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

# 检查组件是否已安装的函数
check_installed() {
    local package=$1
    dpkg -l | grep -q "^ii.*$package"
    return $?
}

check_service_active() {
    local service=$1
    systemctl is-active --quiet "$service"
    return $?
}

# 第1阶段：安装基础工具
log "Stage 1: Installing basic tools..."
for tool in curl wget git unzip net-tools; do
    if ! check_installed "$tool"; then
        log "Installing $tool..."
        apt-get install -y "$tool" || error "Failed to install $tool"
    else
        log "$tool is already installed"
    fi
done

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
    log "Installing MariaDB 10.6 for ARM64..."
    
    # 添加 MariaDB 仓库
    log "Adding MariaDB repository..."
    curl -LsS https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /usr/share/keyrings/mariadb-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/mariadb-keyring.gpg] https://archive.mariadb.org/mariadb-10.6/repo/debian/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/mariadb.list
    
    # 安装 MariaDB
    apt-get update || error "Failed to update package lists after adding MariaDB repository"
    apt-get install -y mariadb-server mariadb-client || error "Failed to install MariaDB 10.6"
    
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
if ! check_installed "php8.2-fpm"; then
    log "Installing PHP and extensions..."
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
else
    log "PHP 8.2 is already installed"
fi

# 第4阶段：安装Web服务器
log "Stage 4: Installing Nginx..."
if ! check_installed "nginx"; then
    # 添加 Nginx 官方仓库
    log "Adding Nginx official repository..."
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list

    # 移除可能存在的旧版本
    apt-get remove -y nginx nginx-common || true
    apt-get autoremove -y

    # 更新包列表并安装 Nginx
    apt-get update || error "Failed to update package lists after adding Nginx repository"
    apt-get install -y nginx=1.24.* || error "Failed to install Nginx 1.24"
    systemctl start nginx
    systemctl enable nginx
else
    log "Nginx is already installed"
    nginx -v
fi

# 第5阶段：安装缓存和消息队列
log "Stage 5: Installing caching and message queue services..."
# Redis
if ! check_installed "redis-server"; then
    log "Installing Redis..."
    log "Adding Redis repository..."
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
    apt-get update || error "Failed to update package lists after adding Redis repository"

    # 安装 Redis
    apt-get install -y redis-server || error "Failed to install Redis"

    # 验证 Redis 版本
    REDIS_VERSION=$(redis-server --version | grep -o "v=[0-9.]*" | cut -d= -f2)
    if [[ ! "$REDIS_VERSION" =~ ^7\.2\..* ]]; then
        warn "Installed Redis version $REDIS_VERSION is not 7.2.x"
    fi

    systemctl start redis-server
    systemctl enable redis-server
else
    log "Redis is already installed"
    redis-cli --version
fi

# Memcached
if ! check_installed "memcached"; then
    log "Installing Memcached..."
    apt-get install -y memcached php8.2-memcached || error "Failed to install Memcached"
    systemctl start memcached
    systemctl enable memcached
else
    log "Memcached is already installed"
    memcached -h | head -n1
fi

# RabbitMQ
if ! check_installed "rabbitmq-server"; then
    log "Installing RabbitMQ..."
    log "Adding RabbitMQ and Erlang repositories..."

    # 彻底清理 RabbitMQ 和 Erlang 的残留
    log "Cleaning up previous RabbitMQ installations..."
    # 停止服务
    systemctl stop rabbitmq-server || true
    systemctl stop erlang || true

    # 删除包
    apt-get remove --purge -y rabbitmq-server erlang* || true
    apt-get autoremove -y
    apt-get autoclean

    # 删除配置文件和数据
    rm -rf /var/lib/rabbitmq/
    rm -rf /var/log/rabbitmq/
    rm -rf /etc/rabbitmq/
    rm -rf /usr/lib/rabbitmq/
    rm -f /etc/apt/sources.list.d/rabbitmq*
    rm -f /etc/apt/sources.list.d/erlang*
    rm -f /usr/share/keyrings/rabbitmq*
    rm -f /usr/share/keyrings/net.launchpad.ppa.rabbitmq*
    rm -f /etc/apt/trusted.gpg.d/rabbitmq*

    # 清理 apt 缓存
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    apt-get update

    if [[ "$ARCH" == "x86_64" ]]; then
        # x86_64 架构使用 RabbitMQ 官方仓库
        log "Installing RabbitMQ for x86_64 architecture..."
        
        # 添加 Erlang 仓库密钥
        curl -1sLf "https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/gpg.E495BB49CC4BBE5B.key" | gpg --dearmor > /usr/share/keyrings/rabbitmq-erlang.gpg
        
        # 添加 RabbitMQ 服务器仓库密钥
        curl -1sLf "https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/gpg.9F4587F226208342.key" | gpg --dearmor > /usr/share/keyrings/rabbitmq-server.gpg
        
        tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
deb [signed-by=/usr/share/keyrings/rabbitmq-erlang.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/debian $(lsb_release -cs) main
deb [signed-by=/usr/share/keyrings/rabbitmq-server.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/debian $(lsb_release -cs) main
EOF
        
        # 更新包列表
        apt-get update || error "Failed to update package lists after adding repositories"
        
        # 安装 Erlang 和 RabbitMQ
        log "Installing Erlang and RabbitMQ..."
        apt-get install -y erlang-base \
            erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
            erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
            erlang-runtime-tools erlang-snmp erlang-ssl \
            erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl \
            rabbitmq-server || error "Failed to install Erlang and RabbitMQ"
    else
        # ARM64 架构使用系统仓库的 RabbitMQ
        log "Installing RabbitMQ for ARM64 architecture..."
        apt-get install -y rabbitmq-server || error "Failed to install RabbitMQ"
    fi

    systemctl start rabbitmq-server
    systemctl enable rabbitmq-server

    # 启用 RabbitMQ 管理插件
    rabbitmq-plugins enable rabbitmq_management
else
    log "RabbitMQ is already installed"
    rabbitmqctl version
fi

# 第6阶段：安装性能优化工具
log "Stage 6: Installing performance optimization tools..."
# Varnish
if ! check_installed "varnish"; then
    log "Installing Varnish..."
    apt-get install -y varnish=7.5.* || error "Failed to install Varnish 7.5"
    systemctl start varnish
    systemctl enable varnish
else
    log "Varnish is already installed"
    varnishd -V
fi

# OpenSearch
if [[ ! -d "/usr/local/opensearch" ]]; then
    log "Installing OpenSearch..."
    log "Installing OpenSearch 2.12..."
    wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.12.0/opensearch-2.12.0-linux-x64.tar.gz
    tar -xzf opensearch-2.12.0-linux-x64.tar.gz
    mv opensearch-2.12.0 /usr/local/opensearch
    rm opensearch-2.12.0-linux-x64.tar.gz
else
    log "OpenSearch is already installed"
fi

# 第7阶段：安装管理工具
log "Stage 7: Installing management tools..."
# Composer
if ! command -v composer &> /dev/null; then
    log "Installing Composer..."
    log "Installing Composer 2.7..."
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        rm composer-setup.php
        error "Composer installer corrupt"
    fi
    php composer-setup.php --version=2.7.1 --install-dir=/usr/local/bin --filename=composer --no-interaction
    rm composer-setup.php
else
    log "Composer is already installed"
    COMPOSER_ALLOW_SUPERUSER=1 composer --version | sed 's/^/Composer: /'
fi

# phpMyAdmin
if ! check_installed "phpmyadmin"; then
    log "Installing phpMyAdmin..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin || error "Failed to install phpMyAdmin"
else
    log "phpMyAdmin is already installed"
fi

# Webmin
if ! check_installed "webmin"; then
    log "Installing Webmin..."
    apt-get install -y webmin || error "Failed to install Webmin"
else
    log "Webmin is already installed"
fi

# 第8阶段：安装安全组件
log "Stage 8: Installing security components..."
# Fail2ban
if ! check_installed "fail2ban"; then
    log "Installing Fail2ban..."
    log "Installing and configuring Fail2ban..."
    apt-get install -y fail2ban || error "Failed to install Fail2ban"
    systemctl start fail2ban
    systemctl enable fail2ban

    # 配置 Fail2ban
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

    # 重启 Fail2ban 使配置生效
    systemctl restart fail2ban
else
    log "Fail2ban is already installed"
fi

# Certbot
apt-get install -y certbot python3-certbot-nginx || error "Failed to install Certbot"

# 输出安装版本信息
log "Installation completed successfully!"
log "Installed versions:"
echo "----------------------------------------"
nginx -v 2>&1 | sed 's/^/Nginx: /'
if [[ "$ARCH" == "x86_64" ]]; then
    mysql --version | sed 's/^/MySQL: /'
else
    mariadb --version | sed 's/^/MariaDB: /'
fi
php --version | head -n1 | sed 's/^/PHP: /'
redis-cli --version | sed 's/^/Redis: /'
rabbitmqctl version | head -n1 | sed 's/^/RabbitMQ: /'
varnishd -V 2>&1 | head -n1 | sed 's/^/Varnish: /'
COMPOSER_ALLOW_SUPERUSER=1 composer --version | sed 's/^/Composer: /'
echo "OpenSearch: 2.12.0"
dpkg -l | grep "^ii.*phpmyadmin" | head -n1 | awk '{print "phpMyAdmin: " $3}'
memcached -h | head -n1 | sed 's/^/Memcached: /'
dpkg -l | grep "^ii.*webmin" | awk '{print "Webmin: " $3}'
dpkg -l | grep "^ii.*fail2ban" | awk '{print "Fail2ban: " $3}'
echo "----------------------------------------"
