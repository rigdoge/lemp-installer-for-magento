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

# 检查和更新系统
log "Updating system packages..."
apt-get update || error "Failed to update system packages"
apt-get upgrade -y || error "Failed to upgrade system packages"

# 第1阶段：安装基础工具
log "Stage 1: Installing basic tools..."
apt-get install -y curl wget git unzip net-tools || error "Failed to install basic tools"

# 添加所有必要的软件源
log "Adding required repositories..."

# MySQL 8.0 Repository
log "Adding MySQL repository..."

# 清理之前的 MySQL 残留
log "Cleaning up previous MySQL installations..."
# 停止可能运行的 MySQL 服务
systemctl stop mysql || true
systemctl stop mysqld || true
systemctl stop mariadb || true

# 删除所有 MySQL 相关包
apt-get remove --purge -y mysql* mariadb*
apt-get autoremove -y
apt-get autoclean

# 删除 MySQL 配置和数据文件
rm -rf /etc/mysql /var/lib/mysql /var/log/mysql
rm -f /etc/apt/sources.list.d/mysql.list
rm -f /usr/share/keyrings/mysql*

if [[ "$ARCH" == "x86_64" ]]; then
    # 添加 MySQL GPG key 和仓库
    log "Adding MySQL repository..."
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B7B3B788A8D3785C
    echo "deb http://repo.mysql.com/apt/debian $(lsb_release -sc) mysql-8.0" | tee /etc/apt/sources.list.d/mysql.list
    
    # 更新包列表
    apt-get update || error "Failed to update package lists after adding MySQL repository"
    
    # 安装 MySQL
    log "Installing MySQL..."
    apt-get install -y mysql-server
    
    # 启动 MySQL
    systemctl start mysql || error "Failed to start MySQL"
    systemctl enable mysql
else
    # 安装 MariaDB
    log "Installing MariaDB for ARM64..."
    apt-get install -y mariadb-server mariadb-client
    
    # 启动 MariaDB
    systemctl start mariadb || error "Failed to start MariaDB"
    systemctl enable mariadb
fi

# 等待数据库完全启动
log "Waiting for database to start..."
for i in {1..30}; do
    if [[ "$ARCH" == "x86_64" ]]; then
        if mysqladmin ping &>/dev/null; then
            break
        fi
    else
        if mysqladmin ping &>/dev/null; then
            break
        fi
    fi
    sleep 1
done

# 设置 root 密码
log "Setting database root password..."
if [[ "$ARCH" == "x86_64" ]]; then
    if mysqladmin -u root password "${DB_ROOT_PASSWORD}"; then
        log "MySQL root password set successfully"
    else
        error "Failed to set MySQL root password"
    fi
else
    if mysqladmin -u root password "${DB_ROOT_PASSWORD}"; then
        log "MariaDB root password set successfully"
    else
        error "Failed to set MariaDB root password"
    fi
fi

# 配置数据库
log "Configuring database..."
cat > /etc/mysql/conf.d/magento.cnf <<EOF
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
max_allowed_packet = 256M
innodb_file_per_table = 1
innodb_open_files = 400
innodb_io_capacity = 400
innodb_flush_method = O_DIRECT
innodb_thread_concurrency = 4
innodb_lock_wait_timeout = 50
transaction-isolation = READ-COMMITTED
EOF

# 重启数据库使配置生效
if [[ "$ARCH" == "x86_64" ]]; then
    systemctl restart mysql || error "Failed to restart MySQL"
else
    systemctl restart mariadb || error "Failed to restart MariaDB"
fi

# 设置数据库安全配置
log "Securing database installation..."
if mysql -u root -p"${DB_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
then
    if [[ "$ARCH" == "x86_64" ]]; then
        log "MySQL security configuration completed successfully"
    else
        log "MariaDB security configuration completed successfully"
    fi
else
    if [[ "$ARCH" == "x86_64" ]]; then
        error "Failed to configure MySQL security settings"
    else
        error "Failed to configure MariaDB security settings"
    fi
fi

# 第3阶段：安装PHP和扩展
log "Stage 3: Installing PHP and extensions..."
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

# 第4阶段：安装Web服务器
log "Stage 4: Installing Nginx..."

# 添加 Nginx 官方仓库
log "Adding Nginx official repository..."
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list
apt-get update || error "Failed to update package lists after adding Nginx repository"

# 安装 Nginx
apt-get install -y --allow-downgrades nginx=1.24.* || error "Failed to install Nginx 1.24"
systemctl start nginx
systemctl enable nginx

# 第5阶段：安装缓存和消息队列
log "Stage 5: Installing caching and message queue services..."
# Redis
apt-get install -y redis-server=7:7.2.* || error "Failed to install Redis 7.2"
systemctl start redis-server
systemctl enable redis-server

# Memcached
apt-get install -y memcached php8.2-memcached || error "Failed to install Memcached"
systemctl start memcached
systemctl enable memcached

# RabbitMQ
apt-get install -y rabbitmq-server=3.13.* || error "Failed to install RabbitMQ 3.13"
systemctl start rabbitmq-server
systemctl enable rabbitmq-server

# 第6阶段：安装性能优化工具
log "Stage 6: Installing performance optimization tools..."
# Varnish
apt-get install -y varnish=7.5.* || error "Failed to install Varnish 7.5"
systemctl start varnish
systemctl enable varnish

# OpenSearch
log "Installing OpenSearch 2.12..."
wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.12.0/opensearch-2.12.0-linux-x64.tar.gz
tar -xzf opensearch-2.12.0-linux-x64.tar.gz
mv opensearch-2.12.0 /usr/local/opensearch
rm opensearch-2.12.0-linux-x64.tar.gz

# 第7阶段：安装管理工具
log "Stage 7: Installing management tools..."
# Composer
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

# phpMyAdmin
DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin || error "Failed to install phpMyAdmin"

# Webmin
apt-get install -y webmin || error "Failed to install Webmin"

# 第8阶段：安装安全组件
log "Stage 8: Installing security components..."
# ModSecurity
apt-get install -y nginx-module-modsecurity modsecurity-crs || error "Failed to install ModSecurity for Nginx"

# Configure ModSecurity
log "Configuring ModSecurity..."
mkdir -p /etc/nginx/modsec
wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

# Download and configure OWASP CRS
wget https://github.com/coreruleset/coreruleset/archive/v3.3.5.tar.gz
tar -xzf v3.3.5.tar.gz
mv coreruleset-3.3.5/rules /etc/nginx/modsec/
rm -rf coreruleset-3.3.5 v3.3.5.tar.gz

# Create main ModSecurity configuration file
cat > /etc/nginx/modsec/main.conf <<EOF
Include /etc/nginx/modsec/modsecurity.conf
Include /etc/nginx/modsec/rules/*.conf

# Magento specific rules
SecRule REQUEST_URI "@beginsWith /admin" "id:1000,phase:1,pass,nolog,ctl:ruleEngine=Off"
SecRule REQUEST_URI "@beginsWith /static/" "id:1001,phase:1,pass,nolog,ctl:ruleEngine=Off"
SecRule REQUEST_URI "@beginsWith /media/" "id:1002,phase:1,pass,nolog,ctl:ruleEngine=Off"
EOF

# Add ModSecurity module to Nginx configuration
cat > /etc/nginx/conf.d/modsecurity.conf <<EOF
load_module modules/ngx_http_modsecurity_module.so;

modsecurity on;
modsecurity_rules_file /etc/nginx/modsec/main.conf;
EOF

# Fail2ban
apt-get install -y fail2ban || error "Failed to install Fail2ban"
systemctl start fail2ban
systemctl enable fail2ban

# Configure Fail2ban
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
maxretry = 3

[nginx-http-auth]
enabled = true

[nginx-botsearch]
enabled = true

[nginx-badbots]
enabled = true

[nginx-noscript]
enabled = true

[nginx-req-limit]
enabled = true
EOF

# Certbot
apt-get install -y certbot python3-certbot-nginx || error "Failed to install Certbot"

# 输出安装版本信息
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
dpkg -l | grep phpmyadmin | awk '{print "phpMyAdmin " $3}'
memcached -h | head -n1
dpkg -l | grep webmin | awk '{print "Webmin " $3}'
dpkg -l | grep fail2ban | awk '{print "Fail2ban " $3}'
dpkg -l | grep modsecurity | awk '{print "ModSecurity " $3}'
