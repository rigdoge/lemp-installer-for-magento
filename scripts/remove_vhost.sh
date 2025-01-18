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
if [ "$#" -ne 1 ]; then
    error "Usage: $0 <domain>"
fi

DOMAIN=$1

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 删除 Nginx 配置
log "Removing Nginx configuration for $DOMAIN..."

# 删除符号链接
if [ -L "/etc/nginx/sites-enabled/$DOMAIN.conf" ]; then
    log "Removing symbolic link..."
    rm "/etc/nginx/sites-enabled/$DOMAIN.conf"
fi

# 删除配置文件
if [ -f "/etc/nginx/sites-available/$DOMAIN.conf" ]; then
    log "Removing configuration file..."
    rm "/etc/nginx/sites-available/$DOMAIN.conf"
fi

# 删除日志文件
if [ -f "/var/log/nginx/$DOMAIN.access.log" ]; then
    log "Removing access log..."
    rm "/var/log/nginx/$DOMAIN.access.log"
fi

if [ -f "/var/log/nginx/$DOMAIN.error.log" ]; then
    log "Removing error log..."
    rm "/var/log/nginx/$DOMAIN.error.log"
fi

# 删除 PHP-FPM 配置
if [ -f "/etc/php/8.2/fpm/pool.d/magento.conf" ]; then
    log "Removing PHP-FPM pool configuration..."
    rm "/etc/php/8.2/fpm/pool.d/magento.conf"
fi

# 恢复默认的 PHP-FPM www 池
if [ -f "/etc/php/8.2/fpm/pool.d/www.conf.disabled" ]; then
    log "Restoring default PHP-FPM pool..."
    mv /etc/php/8.2/fpm/pool.d/www.conf.disabled /etc/php/8.2/fpm/pool.d/www.conf
fi

# 删除 PHP-FPM sock 文件
if [ -S "/run/php/php8.2-fpm-magento.sock" ]; then
    log "Removing PHP-FPM socket file..."
    rm "/run/php/php8.2-fpm-magento.sock"
fi

# 重启 PHP-FPM
log "Restarting PHP-FPM..."
systemctl restart php8.2-fpm || warn "Failed to restart PHP-FPM"

# 测试 Nginx 配置
log "Testing Nginx configuration..."
nginx -t || error "Nginx configuration test failed"

# 重启 Nginx
log "Restarting Nginx..."
systemctl restart nginx || error "Failed to restart Nginx"

log "Virtual host configuration removed successfully!" 