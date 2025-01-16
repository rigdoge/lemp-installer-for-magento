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
if [ "$#" -ne 1 ]; then
    error "Usage: $0 <domain>"
fi

DOMAIN=$1

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 检查是否安装了 certbot
if ! command -v certbot &> /dev/null; then
    log "Installing certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
fi

# 获取并安装 SSL 证书
log "Obtaining SSL certificate for $DOMAIN..."
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email webmaster@"$DOMAIN" --redirect

# 检查证书状态
log "Checking certificate status..."
certbot certificates

# 设置自动续期
log "Setting up automatic renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer
systemctl status --no-pager certbot.timer

# 测试续期
log "Testing certificate renewal..."
certbot renew --dry-run

log "SSL configuration completed for $DOMAIN"
log "Certificate will be automatically renewed before expiration" 