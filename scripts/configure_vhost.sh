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

# 检查模板文件是否存在
TEMPLATE_FILE="../templates/magento.conf.template"
if [ ! -f "$TEMPLATE_FILE" ]; then
    error "Template file not found: $TEMPLATE_FILE"
fi

# 创建配置文件
log "Creating Nginx configuration for $DOMAIN..."
CONF_FILE="/etc/nginx/sites-available/$DOMAIN.conf"

# 复制并替换模板中的变量
cp "$TEMPLATE_FILE" "$CONF_FILE"
sed -i "s|{{DOMAIN}}|$DOMAIN|g" "$CONF_FILE"
sed -i "s|{{MAGENTO_ROOT}}|$MAGENTO_ROOT|g" "$CONF_FILE"
sed -i "s|{{MAGENTO_MODE}}|$MAGENTO_MODE|g" "$CONF_FILE"

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