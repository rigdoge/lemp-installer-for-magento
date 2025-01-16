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

# 添加必要的软件源
log "Adding required repositories..."

# MySQL 8.0 Repository
wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.29-1_all.deb
rm mysql-apt-config_0.8.29-1_all.deb

# Redis 7.2 Repository
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/redis.list

# RabbitMQ 3.13 Repository
curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | gpg --dearmor > /usr/share/keyrings/com.rabbitmq.team.gpg
curl -1sLf "https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/gpg.E495BB49CC4BBE5B.key" | gpg --dearmor > /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg
curl -1sLf "https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/gpg.9F4587F226208342.key" | gpg --dearmor > /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg

echo "deb [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/debian bullseye main" > /etc/apt/sources.list.d/rabbitmq-erlang.list
echo "deb [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/debian bullseye main" > /etc/apt/sources.list.d/rabbitmq-server.list

# Varnish 7.5 Repository
curl -s https://packagecloud.io/install/repositories/varnishcache/varnish75/script.deb.sh | bash

# 更新包列表
apt-get update

# 安装指定版本的软件包
log "Installing specified versions of required packages..."

# Nginx 1.24.0
log "Installing Nginx 1.24.0..."
apt-get install -y nginx=1.24.0-1 || error "Failed to install Nginx 1.24.0"

# MySQL 8.0.36
log "Installing MySQL 8.0.36..."
apt-get install -y mysql-server=8.0.36-1 || error "Failed to install MySQL 8.0.36"

# PHP 8.2
log "Installing PHP 8.2 and extensions..."
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

# Redis 7.2
log "Installing Redis 7.2..."
apt-get install -y redis-server=7:7.2.* || error "Failed to install Redis 7.2"

# RabbitMQ 3.13
log "Installing RabbitMQ 3.13..."
apt-get install -y rabbitmq-server=3.13.* || error "Failed to install RabbitMQ 3.13"

# Varnish 7.5
log "Installing Varnish 7.5..."
apt-get install -y varnish=7.5.* || error "Failed to install Varnish 7.5"

# OpenSearch 2.12
log "Installing OpenSearch 2.12..."
wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.12.0/opensearch-2.12.0-linux-x64.tar.gz
tar -xzf opensearch-2.12.0-linux-x64.tar.gz
mv opensearch-2.12.0 /usr/local/opensearch
rm opensearch-2.12.0-linux-x64.tar.gz

# Composer 2.7
log "Installing Composer 2.7..."
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    rm composer-setup.php
    error "Composer installer corrupt"
fi
php composer-setup.php --version=2.7.1 --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

# 启动服务
log "Starting services..."
systemctl start nginx
systemctl enable nginx
systemctl start mysql
systemctl enable mysql
systemctl start php8.2-fpm
systemctl enable php8.2-fpm
systemctl start redis-server
systemctl enable redis-server
systemctl start rabbitmq-server
systemctl enable rabbitmq-server
systemctl start varnish
systemctl enable varnish

log "Installation completed successfully!"
log "Installed versions:"
nginx -v
mysql --version
php --version
redis-cli --version
rabbitmqctl version
varnishd -V
composer --version
echo "OpenSearch 2.12.0"
