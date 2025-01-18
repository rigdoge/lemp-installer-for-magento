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

# 检查系统内存
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
log "Total system memory: ${TOTAL_MEM}GB"

# 优化PHP-FPM
optimize_php_fpm() {
    log "Optimizing PHP-FPM configuration..."
    
    PHP_FPM_CONF="/etc/php/8.2/fpm/pool.d/www.conf"
    
    # 根据系统内存和架构调整PHP-FPM进程数
    if [[ "$ARCH" == "aarch64" ]]; then
        # ARM架构使用更保守的配置
        PM_MAX_CHILDREN=$(( $TOTAL_MEM * 4 ))
        PM_START_SERVERS=2
        PM_MIN_SPARE_SERVERS=1
        PM_MAX_SPARE_SERVERS=3
        PM_TYPE="ondemand"
    else
        # x86_64架构使用原有配置
        if [ $TOTAL_MEM -le 2 ]; then
            PM_MAX_CHILDREN=10
            PM_START_SERVERS=2
            PM_MIN_SPARE_SERVERS=2
            PM_MAX_SPARE_SERVERS=4
        elif [ $TOTAL_MEM -le 4 ]; then
            PM_MAX_CHILDREN=20
            PM_START_SERVERS=4
            PM_MIN_SPARE_SERVERS=4
            PM_MAX_SPARE_SERVERS=8
        else
            PM_MAX_CHILDREN=50
            PM_START_SERVERS=5
            PM_MIN_SPARE_SERVERS=5
            PM_MAX_SPARE_SERVERS=10
        fi
        PM_TYPE="dynamic"
    fi
    
    sed -i "s/^pm =.*/pm = $PM_TYPE/" $PHP_FPM_CONF
    sed -i "s/^pm.max_children =.*/pm.max_children = $PM_MAX_CHILDREN/" $PHP_FPM_CONF
    sed -i "s/^pm.start_servers =.*/pm.start_servers = $PM_START_SERVERS/" $PHP_FPM_CONF
    sed -i "s/^pm.min_spare_servers =.*/pm.min_spare_servers = $PM_MIN_SPARE_SERVERS/" $PHP_FPM_CONF
    sed -i "s/^pm.max_spare_servers =.*/pm.max_spare_servers = $PM_MAX_SPARE_SERVERS/" $PHP_FPM_CONF
    
    # 优化PHP OPcache
    PHP_INI="/etc/php/8.2/fpm/php.ini"
    if [[ "$ARCH" == "aarch64" ]]; then
        # ARM架构使用较小的内存配置
        sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=128/' $PHP_INI
    else
        sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/' $PHP_INI
    fi
    
    sed -i 's/^;opcache.enable=.*/opcache.enable=1/' $PHP_INI
    sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=100000/' $PHP_INI
    sed -i 's/^;opcache.revalidate_freq=.*/opcache.revalidate_freq=0/' $PHP_INI
    sed -i 's/^;opcache.save_comments=.*/opcache.save_comments=1/' $PHP_INI
}

# 优化Nginx
optimize_nginx() {
    log "Optimizing Nginx configuration..."
    
    NGINX_CONF="/etc/nginx/nginx.conf"
    
    # 根据CPU核心数调整worker进程
    CPU_CORES=$(nproc)
    sed -i "s/^worker_processes.*/worker_processes $CPU_CORES;/" $NGINX_CONF
    
    # 调整worker连接数
    sed -i 's/^worker_connections.*/worker_connections 2048;/' $NGINX_CONF
    
    # 添加FastCGI缓存配置
    cat > /etc/nginx/conf.d/fastcgi_cache.conf <<EOF
fastcgi_cache_path /tmp/nginx_cache levels=1:2 keys_zone=MAGENTO:100m inactive=60m;
fastcgi_cache_key "\$request_method\$request_uri";
fastcgi_cache_use_stale error timeout invalid_header http_500;
fastcgi_cache_valid 200 60m;
EOF
}

# 优化MySQL
optimize_mysql() {
    log "Optimizing MySQL configuration..."
    
    MYSQL_CONF="/etc/mysql/conf.d/magento.cnf"
    
    # 根据系统内存和架构调整MySQL配置
    if [[ "$ARCH" == "aarch64" ]]; then
        # ARM架构使用更保守的配置
        BUFFER_POOL_SIZE="$(( $TOTAL_MEM * 512 ))M"
        THREAD_CACHE_SIZE=$(( $TOTAL_MEM * 4 ))
    else
        # x86_64架构使用原有配置
        if [ $TOTAL_MEM -le 2 ]; then
            BUFFER_POOL_SIZE="512M"
            THREAD_CACHE_SIZE=8
        elif [ $TOTAL_MEM -le 4 ]; then
            BUFFER_POOL_SIZE="1G"
            THREAD_CACHE_SIZE=16
        else
            BUFFER_POOL_SIZE="2G"
            THREAD_CACHE_SIZE=32
        fi
    fi
    
    cat > $MYSQL_CONF <<EOF
[mysqld]
innodb_buffer_pool_size = $BUFFER_POOL_SIZE
innodb_log_file_size = 256M
innodb_log_buffer_size = 8M
innodb_file_per_table = 1
innodb_open_files = 400
innodb_io_capacity = 400
innodb_flush_method = O_DIRECT
innodb_thread_concurrency = 0
innodb_read_io_threads = 4
innodb_write_io_threads = 4
innodb_stats_on_metadata = 0
innodb_buffer_pool_instances = 8

thread_cache_size = $THREAD_CACHE_SIZE
max_connections = 150
max_allowed_packet = 128M

query_cache_type = 0
query_cache_size = 0

slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
EOF
}

# 系统优化
optimize_system() {
    log "Optimizing system settings..."
    
    # 调整系统限制
    cat > /etc/security/limits.d/magento.conf <<EOF
* soft nofile 65535
* hard nofile 65535
EOF
    
    # 只调整最基本的内核参数
    cat > /etc/sysctl.d/99-magento.conf <<EOF
# 调整TCP连接的队列长度
net.core.somaxconn = 1024

# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1

# 调整虚拟内存使用倾向
vm.swappiness = 10
EOF
    
    # 应用系统参数
    sysctl -p /etc/sysctl.d/99-magento.conf
}

# 执行优化
log "Starting performance optimization..."
optimize_php_fpm
optimize_nginx
optimize_mysql
optimize_system

# 重启服务
log "Restarting services..."
systemctl restart php8.2-fpm
systemctl restart nginx
systemctl restart mysql

log "Performance optimization completed!"
log "Please monitor system performance and adjust settings as needed." 