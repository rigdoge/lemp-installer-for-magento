# 性能优化指南

## 概述

本文档包含以下优化内容：
1. 系统级优化
2. Nginx 优化
3. PHP-FPM 优化
4. MariaDB 优化
5. Magento 2 优化

## 系统级优化

### 1. 内核参数优化

编辑 `/etc/sysctl.conf`：
```bash
# 文件描述符限制
fs.file-max = 65535

# 网络优化
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_syn_backlog = 4096
net.core.somaxconn = 65535

# 内存管理
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2
```

应用更改：
```bash
sudo sysctl -p
```

### 2. 文件系统优化

```bash
# 使用 noatime 挂载选项
sudo mount -o remount,noatime /

# 调整文件系统预读
sudo blockdev --setra 4096 /dev/sda
```

### 3. 资源限制

编辑 `/etc/security/limits.conf`：
```bash
# 文件描述符限制
* soft nofile 65535
* hard nofile 65535

# 进程数限制
* soft nproc 65535
* hard nproc 65535
```

## Nginx 优化

### 1. 工作进程优化

编辑 `/etc/nginx/nginx.conf`：
```nginx
# 工作进程数
worker_processes auto;
worker_rlimit_nofile 65535;

# 事件模块
events {
    worker_connections 65535;
    multi_accept on;
    use epoll;
}

# HTTP 优化
http {
    # 基础缓冲区
    client_body_buffer_size 16k;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 4 8k;

    # 超时设置
    client_body_timeout 12;
    client_header_timeout 12;
    keepalive_timeout 15;
    send_timeout 10;

    # 文件传输
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    
    # 缓存设置
    open_file_cache max=200000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
}
```

### 2. FastCGI 缓存

```nginx
# FastCGI 缓存配置
fastcgi_cache_path /var/run/nginx-cache levels=1:2 keys_zone=MAGENTO:100m inactive=60m;
fastcgi_cache_key "$request_method$request_uri";
fastcgi_cache_use_stale error timeout invalid_header http_500;
fastcgi_cache_valid 200 60m;

# 页面缓存
location ~ ^/(index|get|static|errors/report|errors/404|errors/503|health_check)\.php$ {
    fastcgi_cache MAGENTO;
    fastcgi_cache_valid 200 60m;
    fastcgi_cache_use_stale error timeout invalid_header http_500;
    fastcgi_cache_min_uses 1;
    fastcgi_cache_lock on;
}
```

### 3. Gzip 压缩

```nginx
# Gzip 设置
gzip on;
gzip_disable "msie6";
gzip_comp_level 6;
gzip_min_length 1100;
gzip_buffers 16 8k;
gzip_proxied any;
gzip_types
    text/plain
    text/css
    text/js
    text/xml
    text/javascript
    application/javascript
    application/x-javascript
    application/json
    application/xml
    application/xml+rss
    image/svg+xml;
```

## PHP-FPM 优化

### 1. 进程管理

编辑 `/etc/php/8.2/fpm/pool.d/www.conf`：
```ini
# 进程管理器设置
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500

# 慢日志
request_slowlog_timeout = 10s
slowlog = /var/log/php8.2-fpm.slow.log
```

### 2. PHP 配置优化

编辑 `/etc/php/8.2/fpm/php.ini`：
```ini
# 内存限制
memory_limit = 756M

# 执行时间
max_execution_time = 1800
max_input_time = 1800

# 上传限制
post_max_size = 64M
upload_max_filesize = 64M

# OPcache 设置
opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 50000
opcache.revalidate_freq = 0
opcache.save_comments = 1
opcache.enable_file_override = 1
```

### 3. 会话处理

```ini
# 会话设置
session.gc_maxlifetime = 28800
session.gc_probability = 1
session.gc_divisor = 100

# 使用 Redis 存储会话
session.save_handler = redis
session.save_path = "tcp://127.0.0.1:6379/2"
```

## MariaDB 优化

### 1. 缓冲池配置

编辑 `/etc/mysql/mariadb.conf.d/50-server.cnf`：
```ini
[mysqld]
# 缓冲池设置
innodb_buffer_pool_size = 70% of total RAM
innodb_buffer_pool_instances = 8

# 日志设置
innodb_log_file_size = 256M
innodb_log_buffer_size = 16M

# 并发设置
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_thread_concurrency = 0

# 其他优化
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
```

### 2. 查询缓存

```ini
# 查询缓存设置
query_cache_type = 1
query_cache_size = 128M
query_cache_limit = 2M

# 临时表设置
tmp_table_size = 64M
max_heap_table_size = 64M
```

### 3. 连接和线程

```ini
# 连接设置
max_connections = 1000
max_connect_errors = 1000000

# 线程缓存
thread_cache_size = 128
thread_stack = 192K
```

## Magento 2 优化

### 1. 缓存配置

```bash
# 启用所有缓存
bin/magento cache:enable

# 使用 Redis 缓存
bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=0

# 使用 Redis 页面缓存
bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=1
```

### 2. 索引器配置

```bash
# 设置索引器为更新时执行
bin/magento indexer:set-mode realtime

# 重建索引
bin/magento indexer:reindex
```

### 3. 静态内容部署

```bash
# 部署静态内容
bin/magento setup:static-content:deploy -f

# 压缩静态文件
find pub/static -type f -name "*.js" -exec gzip -9 {} \;
find pub/static -type f -name "*.css" -exec gzip -9 {} \;
```

## 监控和维护

### 1. 性能监控

```bash
# 安装监控工具
sudo ./scripts/install_monitoring.sh

# 配置性能监控
sudo ./scripts/configure_monitoring.sh
```

### 2. 日志分析

```bash
# 分析慢查询日志
sudo ./scripts/analyze_slow_queries.sh

# 分析 PHP 慢日志
sudo ./scripts/analyze_php_slow.sh
```

### 3. 定期维护

```bash
# 清理日志
sudo ./scripts/cleanup_logs.sh

# 优化数据库
sudo ./scripts/optimize_database.sh

# 清理缓存
sudo ./scripts/clear_cache.sh
```

## 性能测试

### 1. 负载测试

```bash
# 运行负载测试
sudo ./scripts/load_test.sh

# 分析结果
sudo ./scripts/analyze_performance.sh
```

### 2. 监控指标

```bash
# 检查系统负载
htop
iostat
vmstat

# 检查 PHP-FPM 状态
curl localhost/status

# 检查 MySQL 状态
mysqltuner
```

## 故障排除

### 1. 性能问题诊断

```bash
# 检查系统资源
top -c
free -m
df -h

# 检查服务状态
systemctl status nginx php8.2-fpm mariadb
```

### 2. 日志分析

```bash
# 检查错误日志
tail -f /var/log/nginx/error.log
tail -f /var/log/php8.2-fpm.log
tail -f /var/log/mysql/error.log
```

### 3. 紧急处理

```bash
# 重启服务
sudo ./scripts/restart_services.sh

# 清理缓存
sudo ./scripts/emergency_cache_clear.sh

# 释放内存
sudo ./scripts/free_memory.sh
``` 