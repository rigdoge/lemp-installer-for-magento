#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

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

# 检查 Magento 根目录是否存在
if [ ! -d "$MAGENTO_ROOT" ]; then
    error "Magento root directory not found: $MAGENTO_ROOT"
fi

# 检查 Magento 的 Nginx 配置示例文件是否存在
MAGENTO_NGINX_CONF="$MAGENTO_ROOT/nginx.conf.sample"
if [ ! -f "$MAGENTO_NGINX_CONF" ]; then
    error "Magento Nginx configuration sample not found: $MAGENTO_NGINX_CONF"
fi

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
    server unix:/run/php/php8.2-fpm.sock;
}

server {
    listen 80;
    server_name $DOMAIN;
    set \$MAGE_ROOT $MAGENTO_ROOT;
    set \$MAGE_MODE $MAGENTO_MODE;
    
    access_log /var/log/nginx/$DOMAIN.access.log;
    error_log /var/log/nginx/$DOMAIN.error.log;

    include $MAGENTO_ROOT/nginx.conf.sample;
}
EOF

# 创建符号链接
if [ ! -f "/etc/nginx/sites-enabled/$DOMAIN.conf" ]; then
    ln -s "$CONF_FILE" "/etc/nginx/sites-enabled/$DOMAIN.conf"
fi

# 测试Nginx配置
log "Testing Nginx configuration..."
nginx -t || error "Nginx configuration test failed"

# 重启Nginx
log "Restarting Nginx..."
systemctl restart nginx || error "Failed to restart Nginx"

log "Virtual host configuration completed successfully!"
log "Your site should now be accessible at: http://$DOMAIN"
log "Make sure to update your DNS records or local hosts file." 