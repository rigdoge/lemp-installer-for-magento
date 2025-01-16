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

# 使用 doge 用户
PHP_USER="doge"
PHP_GROUP="doge"

# 确保 Magento 目录所有者是 doge
log "Setting Magento directory ownership to doge..."
chown -R $PHP_USER:$PHP_GROUP "$MAGENTO_ROOT"
MAGENTO_OWNER=$PHP_USER
log "Magento directory owner set to: $MAGENTO_OWNER"

# 配置 Nginx 用户
log "Configuring Nginx user..."
if grep -q "^user" /etc/nginx/nginx.conf; then
    sed -i "s/^user.*$/user $PHP_USER $PHP_GROUP;/" /etc/nginx/nginx.conf
else
    # 如果没有找到 user 指令，在文件开头添加
    sed -i "1i user $PHP_USER $PHP_GROUP;" /etc/nginx/nginx.conf
fi

# 确认更改
log "Verifying user configurations..."
echo "Nginx user config:"
grep "^user" /etc/nginx/nginx.conf || error "Failed to set Nginx user"
echo "Magento directory owner:"
stat -c '%U:%G' "$MAGENTO_ROOT"
echo "Current PHP-FPM processes:"
ps aux | grep "php-fpm" | grep -v grep

# 禁用默认的 www pool
log "Disabling default www pool..."
if [ -f "/etc/php/8.2/fpm/pool.d/www.conf" ]; then
    mv /etc/php/8.2/fpm/pool.d/www.conf /etc/php/8.2/fpm/pool.d/www.conf.disabled
    log "Default www pool has been disabled"
fi

# 配置 PHP-FPM 池
log "Configuring PHP-FPM pool..."
PHP_FPM_POOL_CONF="/etc/php/8.2/fpm/pool.d/magento.conf"

# 创建日志目录和文件
log "Creating log directories and files..."
mkdir -p /var/log/php-fpm
touch /var/log/php-fpm/php-fpm.log
touch /var/log/php-fpm/magento-pool.error.log
chown -R $PHP_USER:$PHP_GROUP /var/log/php-fpm
chmod 755 /var/log/php-fpm
chmod 644 /var/log/php-fpm/php-fpm.log
chmod 644 /var/log/php-fpm/magento-pool.error.log
log "PHP-FPM log files created and permissions set"

# 配置 PHP-FPM 主日志
PHP_FPM_CONF="/etc/php/8.2/fpm/php-fpm.conf"
sed -i 's|^error_log.*|error_log = /var/log/php-fpm/php-fpm.log|' "$PHP_FPM_CONF"

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

php_value[memory_limit] = 4G
php_value[max_execution_time] = 18000

catch_workers_output = yes
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /var/log/php-fpm/magento-pool.error.log
php_admin_value[display_errors] = Off
EOF

# 检查并创建必要的目录和权限
log "Setting up directories and permissions..."
directories=(
    "/var/log/php-fpm"
    "/run/php"
    "/var/log/nginx"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    chown $PHP_USER:$PHP_GROUP "$dir"
    chmod 755 "$dir"
    log "Directory $dir: owner=$(stat -c '%U:%G' "$dir"), perms=$(stat -c '%a' "$dir")"
done

# 配置 Nginx
log "Configuring Nginx..."
NGINX_SAMPLE="$MAGENTO_ROOT/nginx.conf.sample"

if [ ! -f "$NGINX_SAMPLE" ]; then
    error "Magento nginx.conf.sample not found at: $NGINX_SAMPLE"
fi

# 创建虚拟主机配置
cat > "/etc/nginx/sites-available/$DOMAIN.conf" <<EOF
upstream fastcgi_backend {
    server unix:/run/php/php8.2-fpm-magento.sock;
}

server {
    listen 80;
    server_name $DOMAIN;
    set \$MAGE_ROOT $MAGENTO_ROOT;
    set \$MAGE_MODE $MAGENTO_MODE;
    
    access_log /var/log/nginx/$DOMAIN.access.log;
    error_log /var/log/nginx/$DOMAIN.error.log;
    
    include $NGINX_SAMPLE;
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
echo "PHP-FPM main error log:"
tail -n 20 /var/log/php-fpm/php-fpm.log || true
echo "PHP-FPM pool error log:"
tail -n 20 /var/log/php-fpm/magento-pool.error.log || true
echo "Nginx main error log:"
tail -n 20 /var/log/nginx/error.log || true
echo "Nginx virtual host error log:"
tail -n 20 /var/log/nginx/$DOMAIN.error.log || true

# 检查 systemd 日志
log "Checking systemd service logs..."
echo "PHP-FPM service status:"
systemctl status --no-pager php8.2-fpm || true
echo "Nginx service status:"
systemctl status --no-pager nginx || true

log "Configuration completed. Please check http://$DOMAIN"
log "If you still see 502 Bad Gateway, please check the logs above for errors." 