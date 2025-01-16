#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
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

# 检查 Magento 根目录是否存在
if [ ! -d "$MAGENTO_ROOT" ]; then
    error "Magento root directory not found: $MAGENTO_ROOT"
fi

# 检查 Magento 的 Nginx 配置示例文件是否存在
MAGENTO_NGINX_CONF="$MAGENTO_ROOT/nginx.conf.sample"
if [ ! -f "$MAGENTO_NGINX_CONF" ]; then
    error "Magento Nginx configuration sample not found: $MAGENTO_NGINX_CONF"
fi

# 获取目录所有者
MAGENTO_OWNER=$(stat -c '%U' "$MAGENTO_ROOT")
log "Detected Magento directory owner: $MAGENTO_OWNER"

# 确保 www-data 用户存在
if ! id -u www-data >/dev/null 2>&1; then
    log "Creating www-data user..."
    useradd -r -s /sbin/nologin www-data
fi

# 将 Magento 所有者添加到 www-data 组
log "Adding $MAGENTO_OWNER to www-data group..."
usermod -a -G www-data "$MAGENTO_OWNER"

# 配置 PHP-FPM 池
log "Configuring PHP-FPM pool..."
PHP_FPM_POOL_CONF="/etc/php/8.2/fpm/pool.d/magento.conf"

# 确保配置目录存在并有正确的权限
log "Setting up PHP-FPM configuration directory..."
mkdir -p /etc/php/8.2/fpm/pool.d
chown root:root /etc/php/8.2/fpm/pool.d
chmod 755 /etc/php/8.2/fpm/pool.d

cat > "$PHP_FPM_POOL_CONF" <<EOF
[magento]
user = www-data
group = www-data
listen = /run/php/php8.2-fpm-magento.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

php_value[memory_limit] = 756M
php_value[max_execution_time] = 18000
php_value[session.auto_start] = Off
php_value[suhosin.session.cryptua] = Off

php_value[error_log] = /var/log/php-fpm/magento-error.log
php_flag[log_errors] = on

security.limit_extensions = .php
EOF

# 设置配置文件权限
log "Setting PHP-FPM configuration file permissions..."
chown root:root "$PHP_FPM_POOL_CONF"
chmod 644 "$PHP_FPM_POOL_CONF"

# 创建 PHP-FPM 日志目录
log "Creating PHP-FPM log directory..."
mkdir -p /var/log/php-fpm
chown www-data:www-data /var/log/php-fpm
chmod 755 /var/log/php-fpm

# 创建 PHP-FPM socket 目录
log "Creating PHP-FPM socket directory..."
mkdir -p /run/php
chown www-data:www-data /run/php
chmod 755 /run/php

# 添加调试信息
log "PHP-FPM Configuration:"
log "Pool directory contents:"
ls -la /etc/php/8.2/fpm/pool.d/
log "Pool configuration:"
cat "$PHP_FPM_POOL_CONF"

# 创建必要的目录
log "Creating Nginx configuration directories..."
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

# 确保 Nginx 配置文件包含 sites-enabled
if ! grep -q "include /etc/nginx/sites-enabled/\*" /etc/nginx/nginx.conf; then
    log "Adding sites-enabled to Nginx configuration..."
    # 在 http 块的末尾添加 include 语句
    sed -i '/http {/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
fi

# 创建配置文件
log "Creating Nginx configuration for $DOMAIN..."
CONF_FILE="/etc/nginx/sites-available/$DOMAIN.conf"

# 创建基本的服务器配置
cat > "$CONF_FILE" <<EOF
upstream fastcgi_backend {
    server unix:/run/php/php8.2-fpm-magento.sock;
}

server {
    listen 80;
    server_name $DOMAIN;
    set \$MAGE_ROOT $MAGENTO_ROOT;
    set \$MAGE_MODE $MAGENTO_MODE;
    
    access_log /var/log/nginx/$DOMAIN.access.log;
    error_log /var/log/nginx/$DOMAIN.error.log debug;

    include $MAGENTO_ROOT/nginx.conf.sample;
}
EOF

# 创建符号链接
if [ ! -f "/etc/nginx/sites-enabled/$DOMAIN.conf" ]; then
    ln -s "$CONF_FILE" "/etc/nginx/sites-enabled/$DOMAIN.conf"
fi

# 设置目录权限
log "Setting directory permissions..."
find "$MAGENTO_ROOT" -type f -exec chmod 644 {} \;
find "$MAGENTO_ROOT" -type d -exec chmod 755 {} \;
chown -R $MAGENTO_OWNER:www-data "$MAGENTO_ROOT"

# 设置特殊目录权限
if [ -d "$MAGENTO_ROOT/var" ]; then
    chmod -R 775 "$MAGENTO_ROOT/var"
fi
if [ -d "$MAGENTO_ROOT/pub/static" ]; then
    chmod -R 775 "$MAGENTO_ROOT/pub/static"
fi
if [ -d "$MAGENTO_ROOT/pub/media" ]; then
    chmod -R 775 "$MAGENTO_ROOT/pub/media"
fi
if [ -d "$MAGENTO_ROOT/app/etc" ]; then
    chmod -R 775 "$MAGENTO_ROOT/app/etc"
fi

# 重启 PHP-FPM
log "Restarting PHP-FPM..."
systemctl restart php8.2-fpm || error "Failed to restart PHP-FPM"

# 验证 PHP-FPM 是否正在运行
if ! systemctl is-active --quiet php8.2-fpm; then
    error "PHP-FPM failed to start. Check logs for details."
fi

# 检查 PHP-FPM sock 文件
if [ ! -S "/run/php/php8.2-fpm-magento.sock" ]; then
    error "PHP-FPM socket file not found"
fi

# 检查 sock 文件权限
ls -l /run/php/php8.2-fpm-magento.sock

# 测试Nginx配置
log "Testing Nginx configuration..."
nginx -t || error "Nginx configuration test failed"

# 重启Nginx
log "Restarting Nginx..."
systemctl restart nginx || error "Failed to restart Nginx"

# 验证 Nginx 是否正在运行
if ! systemctl is-active --quiet nginx; then
    error "Nginx failed to start. Check logs for details."
fi

log "Virtual host configuration completed successfully!"
log "Your site should now be accessible at: http://$DOMAIN"
log "Make sure to update your DNS records or local hosts file."

# 显示一些调试信息
log "Debug information:"
log "PHP-FPM status:"
systemctl status php8.2-fpm
log "Nginx status:"
systemctl status nginx
log "Socket file permissions:"
ls -l /run/php/php8.2-fpm-magento.sock 