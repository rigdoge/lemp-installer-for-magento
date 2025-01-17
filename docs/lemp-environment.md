# LEMP 环境配置指南

## 环境要求

### 系统要求
- Debian 11+ 或 Ubuntu 22.04+
- 最小配置：
  - CPU: 2核
  - 内存: 2GB RAM
  - 磁盘: 20GB
- 推荐配置：
  - CPU: 4核
  - 内存: 4GB RAM
  - 磁盘: 40GB

### 软件版本
- Nginx: 1.18+
- MariaDB: 10.6+
- PHP: 8.2
- OpenSearch: 2.x

## 基础安装

### 1. 准备工作
```bash
# 更新系统
sudo apt update
sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget git unzip
```

### 2. 安装 LEMP 环境
```bash
# 使用安装脚本
sudo ./scripts/install.sh
```

安装脚本会：
1. 安装 Nginx
2. 安装 MariaDB
3. 安装 PHP 8.2 及扩展
4. 配置基本优化参数

### 3. 验证安装
```bash
# 检查 Nginx
nginx -v
systemctl status nginx

# 检查 MariaDB
mysql --version
systemctl status mariadb

# 检查 PHP
php -v
php-fpm8.2 -v
```

## 详细配置

### 1. Nginx 配置

#### 主配置文件
位置：`/etc/nginx/nginx.conf`
```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_disable "msie6";
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

#### 虚拟主机配置
```bash
# 配置虚拟主机
sudo ./scripts/configure_vhost.sh <domain> <magento_root> <magento_mode>

# 示例
sudo ./scripts/configure_vhost.sh magento.example.com /var/www/magento production
```

### 2. MariaDB 配置

#### 安全配置
```bash
# 配置 MariaDB
sudo ./scripts/configure_mysql.sh <db_name> <db_user> <db_password> <root_password>
```

#### 主配置文件
位置：`/etc/mysql/mariadb.conf.d/50-server.cnf`
```ini
[mysqld]
bind-address = 127.0.0.1
max_allowed_packet = 64M
max_connections = 150
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_file_per_table = 1
```

### 3. PHP 配置

#### PHP-FPM 配置
位置：`/etc/php/8.2/fpm/php-fpm.conf`
```ini
[global]
pid = /run/php/php8.2-fpm.pid
error_log = /var/log/php8.2-fpm.log
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
```

#### PHP.ini 配置
位置：`/etc/php/8.2/fpm/php.ini`
```ini
memory_limit = 756M
max_execution_time = 1800
max_input_time = 1800
post_max_size = 64M
upload_max_filesize = 64M
max_input_vars = 3000
realpath_cache_size = 10M
realpath_cache_ttl = 7200
opcache.enable = 1
opcache.memory_consumption = 256
opcache.max_accelerated_files = 50000
opcache.revalidate_freq = 0
session.gc_maxlifetime = 28800
```

## 性能优化

### 1. Nginx 优化
```nginx
# 工作进程优化
worker_processes auto;
worker_rlimit_nofile 65535;

# 连接优化
events {
    worker_connections 65535;
    multi_accept on;
    use epoll;
}

# 缓存优化
fastcgi_cache_path /var/run/nginx-cache levels=1:2 keys_zone=MAGENTO:100m inactive=60m;
fastcgi_cache_key "$request_method$request_uri";
fastcgi_cache_use_stale error timeout invalid_header http_500;
fastcgi_cache_valid 200 60m;
```

### 2. MariaDB 优化
```ini
# 缓冲池优化
innodb_buffer_pool_size = 70% of total RAM
innodb_buffer_pool_instances = 8

# 日志优化
innodb_log_file_size = 256M
innodb_log_buffer_size = 16M

# 并发优化
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_thread_concurrency = 0
```

### 3. PHP-FPM 优化
```ini
# 进程管理
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500

# OPcache 优化
opcache.memory_consumption = 256
opcache.max_accelerated_files = 50000
opcache.revalidate_freq = 0
```

## 安全配置

### 1. 文件权限
```bash
# 设置正确的权限
sudo chown -R www-data:www-data /var/www/magento
sudo find /var/www/magento -type f -exec chmod 644 {} \;
sudo find /var/www/magento -type d -exec chmod 755 {} \;
```

### 2. Nginx 安全设置
```nginx
# 禁用敏感信息
server_tokens off;

# XSS 保护
add_header X-XSS-Protection "1; mode=block";

# 点击劫持保护
add_header X-Frame-Options "SAMEORIGIN";

# MIME 类型嗅探保护
add_header X-Content-Type-Options "nosniff";
```

### 3. MariaDB 安全设置
```bash
# 运行安全配置脚本
sudo mysql_secure_installation

# 限制远程访问
sudo ufw deny 3306
```

## 维护操作

### 1. 备份
```bash
# 执行备份
sudo ./scripts/backup.sh <magento_root> <db_name> <db_user> <db_password>
```

### 2. 日志管理
```bash
# 配置日志轮转
sudo ./scripts/configure_logrotate.sh
```

### 3. 更新
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 更新 PHP
sudo ./scripts/update_php.sh

# 更新 Nginx
sudo ./scripts/update_nginx.sh
```

## 故障排除

### 1. Nginx 问题
```bash
# 检查配置
sudo nginx -t

# 查看错误日志
tail -f /var/log/nginx/error.log
```

### 2. MariaDB 问题
```bash
# 检查状态
systemctl status mariadb

# 查看错误日志
tail -f /var/log/mysql/error.log
```

### 3. PHP-FPM 问题
```bash
# 检查状态
systemctl status php8.2-fpm

# 查看错误日志
tail -f /var/log/php8.2-fpm.log
```

## 监控和维护

### 1. 系统监控
```bash
# 检查系统资源
htop
df -h
free -m
```

### 2. 服务监控
```bash
# 检查所有服务状态
systemctl status nginx mariadb php8.2-fpm

# 检查端口
netstat -tulpn
```

### 3. 日志监控
```bash
# 实时监控所有日志
tail -f /var/log/nginx/error.log /var/log/mysql/error.log /var/log/php8.2-fpm.log
``` 