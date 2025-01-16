#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查参数
if [ "$#" -ne 3 ]; then
    error "Usage: $0 <domain> <magento_root> <magento_mode>"
fi

DOMAIN=$1
MAGENTO_ROOT=$2
MAGENTO_MODE=$3

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 检查目录是否存在
if [ ! -d "$MAGENTO_ROOT" ]; then
    error "Magento root directory not found: $MAGENTO_ROOT"
fi

# 获取目录所有者
MAGENTO_OWNER=$(stat -c '%U' "$MAGENTO_ROOT")
log "Detected Magento directory owner: $MAGENTO_OWNER"

# 使用 doge 用户
PHP_USER="doge"
PHP_GROUP="doge"

# 配置 Nginx 用户
log "Configuring Nginx user..."
sed -i 's/^user  .*$/user  '"$PHP_USER"' '"$PHP_GROUP"';/' /etc/nginx/nginx.conf

# 确认更改
log "Nginx user configuration:"
grep "^user" /etc/nginx/nginx.conf

# 配置 PHP-FPM 池
log "Configuring PHP-FPM pool..."
PHP_FPM_POOL_CONF="/etc/php/8.2/fpm/pool.d/magento.conf"

cat > "$PHP_FPM_POOL_CONF" <<EOF
[magento]
user = $PHP_USER
group = $PHP_GROUP
listen = /run/php/php8.2-fpm-magento.sock
listen.owner = $PHP_USER
listen.group = $PHP_GROUP
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

php_value[memory_limit] = 756M
php_value[max_execution_time] = 18000

php_admin_value[error_log] = /var/log/php-fpm/magento.error.log
php_admin_flag[log_errors] = on
EOF

# 创建日志目录
log "Creating PHP-FPM log directory..."
mkdir -p /var/log/php-fpm
chown $PHP_USER:$PHP_GROUP /var/log/php-fpm
chmod 755 /var/log/php-fpm

# 创建 socket 目录
log "Creating PHP-FPM socket directory..."
mkdir -p /run/php
chown $PHP_USER:$PHP_GROUP /run/php
chmod 755 /run/php

# 创建 Nginx 日志目录
log "Creating Nginx log directory..."
mkdir -p /var/log/nginx
chown $PHP_USER:$PHP_GROUP /var/log/nginx
chmod 755 /var/log/nginx

# 设置目录权限（在后台执行）
log "Setting directory permissions (running in background)..."
{
    chown -R $PHP_USER:$PHP_GROUP "$MAGENTO_ROOT"
    find "$MAGENTO_ROOT" -type f -exec chmod 644 {} \;
    find "$MAGENTO_ROOT" -type d -exec chmod 755 {} \;
    log "Directory permissions update completed."
} &

# 配置 Nginx
log "Configuring Nginx..."
cat > "/etc/nginx/sites-available/$DOMAIN.conf" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    root $MAGENTO_ROOT/pub;
    index index.php;
    
    access_log /var/log/nginx/$DOMAIN.access.log;
    error_log /var/log/nginx/$DOMAIN.error.log;
    
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm-magento.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
}
EOF

# 创建符号链接
ln -sf "/etc/nginx/sites-available/$DOMAIN.conf" "/etc/nginx/sites-enabled/"

# 重启服务
log "Restarting services..."
systemctl restart php8.2-fpm
systemctl restart nginx

# 检查服务状态
log "Checking service status..."
echo "PHP-FPM processes:"
ps aux | grep php-fpm || true
echo "PHP-FPM socket:"
ls -l /run/php/php8.2-fpm-magento.sock || true
echo "Nginx processes:"
ps aux | grep nginx || true
echo "Nginx configuration test:"
nginx -t || true

# 检查日志
log "Checking error logs..."
echo "PHP-FPM error log (main):"
tail -n 20 /var/log/php-fpm.log || true
echo "PHP-FPM error log (pool):"
tail -n 20 /var/log/php-fpm/magento.error.log || true
echo "Nginx main error log:"
tail -n 20 /var/log/nginx/error.log || true
echo "Nginx virtual host error log:"
tail -n 20 /var/log/nginx/$DOMAIN.error.log || true

# 检查 systemd 日志
log "Checking systemd service logs..."
echo "PHP-FPM service status:"
systemctl status php8.2-fpm || true
echo "Nginx service status:"
systemctl status nginx || true

log "Configuration completed. Please check http://$DOMAIN"
log "If you still see 502 Bad Gateway, please check the logs above for errors." 