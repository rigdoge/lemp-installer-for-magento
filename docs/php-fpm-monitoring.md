# PHP-FPM 监控指南

## 功能概述

PHP-FPM 监控模块提供以下功能：
1. 进程状态监控
2. 内存使用监控
3. 慢请求分析
4. 请求队列监控
5. 性能指标收集

## 安装和配置

### 1. 启用监控

```bash
./scripts/plugins/monitoring/commands/enable.sh php-fpm
```

初始化脚本会：
1. 配置 PHP-FPM 状态页面
2. 配置 Nginx 访问规则
3. 设置慢日志记录
4. 启用性能监控

### 2. 配置说明

配置文件位置：`scripts/plugins/monitoring/available/php-fpm.monitor`

```bash
# 监控设置
CHECK_INTERVAL=60          # 检查间隔（秒）
MAX_CHILDREN=50           # 最大子进程数
MIN_SPARE_SERVERS=5       # 最小空闲进程数
MAX_SPARE_SERVERS=35      # 最大空闲进程数
MAX_REQUESTS=500          # 每个子进程最大请求数

# 性能阈值
MAX_PROCESS_USAGE=90      # 最大进程使用率（%）
MAX_MEMORY_USAGE=90       # 最大内存使用率（%）
MAX_REQUEST_TIME=30       # 最大请求时间（秒）
SLOW_REQUEST_TIME=10      # 慢请求阈值（秒）
```

## 监控指标

### 1. 进程状态
- 活动进程数
- 空闲进程数
- 总进程数
- 进程使用率

### 2. 内存使用
- 总内存使用量
- 每个进程平均内存
- 进程数量
- 内存使用率

### 3. 请求处理
- 慢请求数量
- 最近的慢请求
- 请求队列长度
- 处理时间分布

### 4. 性能指标
- 请求处理速率
- 队列等待时间
- 进程重启次数
- 请求拒绝率

## 告警规则

### 1. 错误级别告警
- 服务停止运行
- 内存使用超过阈值
- 进程数超过限制
- 请求队列溢出

### 2. 警告级别告警
- 高进程使用率
- 存在慢请求
- 请求队列积压
- 内存使用接近阈值

## 监控命令

### 1. 查看状态
```bash
./scripts/plugins/monitoring/commands/status.sh
```

输出示例：
```
PHP-FPM Monitor Status Check
===========================
Time: 2024-01-17 10:30:00

Process Status:
- Active processes: 5
- Idle processes: 15
- Total processes: 20

Memory Usage:
- Total Memory: 512 MB
- Average per process: 25.6 MB
- Process count: 20

Slow Requests:
- Total slow requests: 0

Request Queue:
- Queue length: 0

Status: OK
```

### 2. 禁用监控
```bash
./scripts/plugins/monitoring/commands/disable.sh php-fpm
```

## 日志说明

### 1. 慢日志
位置：`/var/log/php8.2-fpm.slow.log`
```
[17-Jan-2024 10:30:00] [pool www] pid 1234
script_filename = /var/www/magento/pub/index.php
[0x00007f9b4c0008c0] execute() /var/www/magento/pub/index.php:23
```

### 2. 错误日志
位置：`/var/log/php8.2-fpm.log`

### 3. 监控日志
位置：`/var/log/php-fpm-monitor.log`

## 性能优化建议

### 1. 进程管理
- 根据服务器资源调整进程数
- 设置合适的最小和最大空闲进程
- 定期检查进程重启情况
- 监控进程生命周期

### 2. 内存管理
- 定期检查内存泄漏
- 设置合理的内存限制
- 监控内存使用趋势
- 及时清理不需要的进程

### 3. 请求处理
- 优化慢请求
- 调整请求超时设置
- 配置合适的队列大小
- 监控请求处理时间

## 故障排除

### 1. 服务问题
```bash
# 检查服务状态
systemctl status php8.2-fpm

# 查看错误日志
tail -f /var/log/php8.2-fpm.log
```

### 2. 性能问题
```bash
# 检查慢日志
tail -f /var/log/php8.2-fpm.slow.log

# 查看进程状态
ps aux | grep php-fpm
```

### 3. 配置问题
```bash
# 检查配置语法
php-fpm8.2 -t

# 查看配置
cat /etc/php/8.2/fpm/pool.d/www.conf
```

## 最佳实践

1. 监控设置
   - 根据实际负载调整阈值
   - 定期检查监控状态
   - 配置告警通知
   - 保存历史数据

2. 性能优化
   - 定期分析慢请求
   - 优化 PHP 配置
   - 调整进程参数
   - 监控资源使用

3. 安全建议
   - 限制状态页面访问
   - 保护监控数据
   - 定期更新配置
   - 记录异常访问 