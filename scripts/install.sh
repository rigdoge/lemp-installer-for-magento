#!/bin/bash

# LEMP Stack Installer for Magento
# Author: Your Name
# Date: $(date)

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

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 检查系统架构
ARCH=$(uname -m)
log "Detected architecture: $ARCH"
if [[ "$ARCH" != "aarch64" && "$ARCH" != "x86_64" ]]; then
    error "Unsupported architecture: $ARCH. This script supports x86_64 and arm64 only."
fi

# 检查操作系统
if [[ ! -f /etc/debian_version ]]; then
    error "This script only works on Debian/Ubuntu systems"
fi

# 检查必要的工具
log "Checking required tools..."
command -v curl >/dev/null 2>&1 || { log "Installing curl..."; apt-get install -y curl; }
command -v wget >/dev/null 2>&1 || { log "Installing wget..."; apt-get install -y wget; }

# 更新系统包
log "Updating system packages..."
apt-get update || error "Failed to update system packages"
apt-get upgrade -y || error "Failed to upgrade system packages"

# 安装Nginx
log "Installing Nginx..."
apt-get install -y nginx || error "Failed to install Nginx"
systemctl start nginx
systemctl enable nginx

# 安装MySQL
log "Installing MySQL..."
apt-get install -y mysql-server || error "Failed to install MySQL"
systemctl start mysql
systemctl enable mysql

# 安装PHP和必要的扩展
log "Installing PHP and required extensions..."
apt-get install -y php8.2-fpm \
    php8.2-cli \
    php8.2-common \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    php8.2-intl \
    php8.2-soap \
    php8.2-xsl || error "Failed to install PHP and extensions"

systemctl start php8.2-fpm
systemctl enable php8.2-fpm

# 配置PHP
log "Configuring PHP..."
PHP_INI="/etc/php/8.2/fpm/php.ini"
PHP_FPM_CONF="/etc/php/8.2/fpm/pool.d/www.conf"

# 根据架构调整PHP配置
if [[ "$ARCH" == "aarch64" ]]; then
    # ARM架构通常内存较小，调整相应参数
    sed -i 's/memory_limit = .*/memory_limit = 1G/' $PHP_INI
    sed -i 's/pm.max_children = .*/pm.max_children = 10/' $PHP_FPM_CONF
    warn "ARM64 architecture detected: PHP memory limit set to 1G"
else
    # x86_64架构使用默认配置
    sed -i 's/memory_limit = .*/memory_limit = 2G/' $PHP_INI
fi

sed -i 's/max_execution_time = .*/max_execution_time = 1800/' $PHP_INI
sed -i 's/zlib.output_compression = .*/zlib.output_compression = On/' $PHP_INI

# 优化PHP-FPM配置
if [[ "$ARCH" == "aarch64" ]]; then
    # ARM架构的优化配置
    sed -i 's/pm = .*/pm = ondemand/' $PHP_FPM_CONF
    sed -i 's/pm.max_children = .*/pm.max_children = 10/' $PHP_FPM_CONF
    sed -i 's/pm.start_servers = .*/pm.start_servers = 2/' $PHP_FPM_CONF
    sed -i 's/pm.min_spare_servers = .*/pm.min_spare_servers = 1/' $PHP_FPM_CONF
    sed -i 's/pm.max_spare_servers = .*/pm.max_spare_servers = 3/' $PHP_FPM_CONF
fi

# 重启服务
log "Restarting services..."
systemctl restart nginx
systemctl restart mysql
systemctl restart php8.2-fpm

log "LEMP stack installation completed successfully!"
log "Architecture-specific optimizations have been applied for: $ARCH"
log "Next steps:"
log "1. Configure MySQL root password"
log "2. Create database for Magento"
log "3. Configure Nginx virtual host"
log "4. Install Magento"
