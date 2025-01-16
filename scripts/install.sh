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

# 检查服务是否正在运行的函数
check_service_active() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        return 0
    fi
    return 1
}

# 检查组件版本的函数
check_version() {
    local component=$1
    local version=$2
    local current_version=$3
    if [[ "$current_version" == *"$version"* ]]; then
        log "$component version $current_version is compatible"
        return 0
    fi
    warn "$component version $current_version might not be compatible"
    return 1
}

# 检查 Nginx 安装和版本
check_nginx() {
    if check_service_active "nginx"; then
        local nginx_version=$(nginx -v 2>&1 | grep -o '[0-9.]*$')
        log "Nginx is running, version: $nginx_version"
        if [[ "$nginx_version" == "1.24."* ]]; then
            log "Nginx version is compatible"
            return 0
        else
            warn "Current Nginx version $nginx_version is not 1.24.x"
            return 1
        fi
    fi
    return 1
}

# 检查 PHP 安装和版本
check_php() {
    if check_service_active "php8.2-fpm"; then
        local php_version=$(php -v | head -n1 | grep -o 'PHP [0-9.]*' | cut -d' ' -f2)
        log "PHP-FPM is running, version: $php_version"
        if [[ "$php_version" == "8.2."* ]]; then
            # 检查所需的 PHP 扩展
            local required_extensions=(
                "mysql" "zip" "gd" "mbstring" "curl" "xml" 
                "bcmath" "intl" "soap" "xsl"
            )
            local missing_extensions=()
            
            for ext in "${required_extensions[@]}"; do
                if ! php -m | grep -q "^$ext$"; then
                    missing_extensions+=("$ext")
                fi
            done
            
            if [ ${#missing_extensions[@]} -eq 0 ]; then
                log "All required PHP extensions are installed"
                return 0
            else
                warn "Missing PHP extensions: ${missing_extensions[*]}"
                return 1
            fi
        else
            warn "Current PHP version $php_version is not 8.2.x"
            return 1
        fi
    fi
    return 1
}

# 检查 Redis 安装和版本
check_redis() {
    if check_service_active "redis-server"; then
        local redis_version=$(redis-cli --version | grep -o '[0-9.]*')
        log "Redis is running, version: $redis_version"
        if [[ "$redis_version" == "7.2."* ]]; then
            log "Redis version is compatible"
            return 0
        else
            warn "Current Redis version $redis_version is not 7.2.x"
            return 1
        fi
    fi
    return 1
}

# 检查 RabbitMQ 安装和版本
check_rabbitmq() {
    if check_service_active "rabbitmq-server"; then
        local rabbitmq_version=$(rabbitmqctl version | head -n1)
        log "RabbitMQ is running, version: $rabbitmq_version"
        # RabbitMQ 版本检查可以根据需要添加
        return 0
    fi
    return 1
}

# 检查 Varnish 安装和版本
check_varnish() {
    if check_service_active "varnish"; then
        local varnish_version=$(varnishd -V 2>&1 | grep -o 'varnish-[0-9.]*' | cut -d- -f2)
        log "Varnish is running, version: $varnish_version"
        if [[ "$varnish_version" == "7.5."* ]]; then
            log "Varnish version is compatible"
            return 0
        else
            warn "Current Varnish version $varnish_version is not 7.5.x"
            return 1
        fi
    fi
    return 1
}

# 在安装前检查所有组件
log "Checking existing components..."

# 检查 Nginx
if check_nginx; then
    log "Skipping Nginx installation as it's already running with compatible version"
    SKIP_NGINX=true
fi

# 检查 PHP
if check_php; then
    log "Skipping PHP installation as it's already running with compatible version"
    SKIP_PHP=true
fi

# 检查 Redis
if check_redis; then
    log "Skipping Redis installation as it's already running with compatible version"
    SKIP_REDIS=true
fi

# 检查 RabbitMQ
if check_rabbitmq; then
    log "Skipping RabbitMQ installation as it's already running"
    SKIP_RABBITMQ=true
fi

# 检查 Varnish
if check_varnish; then
    log "Skipping Varnish installation as it's already running with compatible version"
    SKIP_VARNISH=true
fi

# 检查 MySQL 服务状态的函数
check_mysql_status() {
    log "Checking MySQL service status..."
    if ! systemctl status mysql >/dev/null 2>&1; then
        warn "MySQL service status check failed"
        log "Checking MySQL error log..."
        if [ -f /var/log/mysql/error.log ]; then
            tail -n 50 /var/log/mysql/error.log
        else
            warn "MySQL error log not found at /var/log/mysql/error.log"
        fi
        return 1
    fi
    return 0
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

# 检查 MySQL 是否已安装并正常运行
log "Checking MySQL installation..."
if systemctl is-active --quiet mysql && mysqladmin ping &>/dev/null; then
    log "MySQL is already running and responding to ping"
    MYSQL_VERSION=$(mysql --version)
    if [[ $MYSQL_VERSION == *"Percona"* ]]; then
        log "Percona MySQL is already installed and running properly"
        log "MySQL version: $MYSQL_VERSION"
    else
        warn "Running MySQL is not Percona Server"
        error "Please backup your data and remove existing MySQL installation first"
    fi
else
    # MySQL 安装和配置部分
    if [[ "$ARCH" == "x86_64" || "$ARCH" == "aarch64" ]]; then
        # 清理之前的数据库安装
        log "Cleaning up previous database installations..."
        
        # 停止所有可能运行的数据库服务
        log "Stopping database services..."
        systemctl stop mysql mysqld mariadb percona-server || true
        
        # 清理所有数据库相关的包
        log "Removing database packages..."
        DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y \
            mysql* \
            mariadb* \
            percona* || true
        
        # 清理依赖
        apt-get autoremove -y
        apt-get autoclean
        
        # 清理数据库文件和配置
        log "Cleaning up database files and configurations..."
        rm -rf /etc/mysql /var/lib/mysql /var/log/mysql
        rm -f /etc/apt/sources.list.d/{mysql,mariadb,percona}*.list
        rm -f /usr/share/keyrings/{mysql,mariadb,percona}*
        
        # 添加 Percona 仓库
        log "Adding Percona repository..."
        if [ ! -f /etc/apt/sources.list.d/percona-release.list ]; then
            curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb || error "Failed to download Percona release package"
            dpkg -i percona-release_latest.generic_all.deb || error "Failed to install Percona release package"
            rm percona-release_latest.generic_all.deb
        fi

        # 设置 Percona 仓库
        log "Setting up Percona repository..."
        percona-release setup ps80 || error "Failed to setup Percona repository"
        
        # 更新包列表
        apt-get update || error "Failed to update package lists after adding Percona repository"
        
        # 安装 Percona MySQL
        log "Installing Percona MySQL 8.0..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            percona-server-client \
            percona-server-server || error "Failed to install Percona MySQL 8.0"
        
        # 确保 MySQL 数据目录存在且权限正确
        log "Setting up MySQL data directory..."
        if [ -d "/var/lib/mysql" ]; then
            log "Cleaning up existing MySQL data directory..."
            rm -rf /var/lib/mysql/*
        fi
        
        mkdir -p /var/lib/mysql
        chown -R mysql:mysql /var/lib/mysql
        chmod 750 /var/lib/mysql
        
        # 初始化 MySQL 数据目录
        log "Initializing MySQL data directory..."
        mysqld --initialize-insecure --user=mysql || error "Failed to initialize MySQL data directory"
        
        # 创建必要的目录和文件
        log "Creating necessary directories and files..."
        mkdir -p /var/run/mysqld
        chown -R mysql:mysql /var/run/mysqld
        chmod 755 /var/run/mysqld
        
        # 创建默认配置文件
        log "Creating default MySQL configuration..."
        cat > /etc/mysql/conf.d/mysql.cnf <<EOF
[mysqld]
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = 3306
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
bind-address = 127.0.0.1
EOF
        
        # 启动 MySQL 服务
        log "Starting MySQL service..."
        if ! systemctl start mysql; then
            error_code=$?
            warn "Failed to start MySQL service (exit code: $error_code)"
            log "Checking MySQL error log..."
            if [ -f /var/log/mysql/error.log ]; then
                tail -n 50 /var/log/mysql/error.log
            fi
            if [ -f /var/lib/mysql/*.err ]; then
                log "Checking MySQL data directory error log..."
                tail -n 50 /var/lib/mysql/*.err
            fi
            journalctl -xeu mysql.service
            error "MySQL service failed to start"
        fi
        
        log "Enabling MySQL service..."
        systemctl enable mysql || warn "Failed to enable MySQL service"
    fi
fi

# 等待数据库完全启动
log "Waiting for database to start..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if mysqladmin ping &>/dev/null; then
        log "MySQL is responding to ping"
        break
    fi
    log "Attempt $attempt/$max_attempts: Waiting for MySQL to start..."
    if [ $attempt -eq $max_attempts ]; then
        check_mysql_status
        error "MySQL did not start after $max_attempts attempts"
    fi
    sleep 2
    ((attempt++))
done

# 设置 root 密码
log "Setting database root password..."
if mysqladmin -u root password "${DB_ROOT_PASSWORD}"; then
    log "MySQL root password set successfully"
else
    error "Failed to set MySQL root password"
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
systemctl restart mysql || error "Failed to restart MySQL"

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
    log "MySQL security configuration completed successfully"
else
    error "Failed to configure MySQL security settings"
fi

# 第3阶段：安装PHP和扩展
log "Stage 3: Installing PHP and extensions..."
if [ "$SKIP_PHP" != "true" ]; then
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
else
    log "Skipping PHP installation"
fi

# 第4阶段：安装Web服务器
log "Stage 4: Installing Nginx..."
if [ "$SKIP_NGINX" != "true" ]; then
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
else
    log "Skipping Nginx installation"
fi

# 第5阶段：安装缓存和消息队列
log "Stage 5: Installing caching and message queue services..."
# Redis
if [ "$SKIP_REDIS" != "true" ]; then
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
else
    log "Skipping Redis installation"
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
if [ "$SKIP_RABBITMQ" != "true" ]; then
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
else
    log "Skipping RabbitMQ installation"
fi

# Varnish
if [ "$SKIP_VARNISH" != "true" ]; then
    if ! check_installed "varnish"; then
        log "Installing Varnish..."
        apt-get install -y varnish=7.5.* || error "Failed to install Varnish 7.5"
        systemctl start varnish
        systemctl enable varnish
    else
        log "Varnish is already installed"
        varnishd -V
    fi
else
    log "Skipping Varnish installation"
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
mysql --version | sed 's/^/MySQL: /'
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
