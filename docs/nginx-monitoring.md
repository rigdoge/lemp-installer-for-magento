# Nginx 监控指南

## 功能概述

Nginx 监控模块提供以下功能：
1. 服务状态监控
2. 连接和请求监控
3. 访问日志分析
4. 错误日志分析
5. SSL 证书监控
6. 缓存性能监控

## 安装和配置

### 1. 启用监控

```bash
./scripts/plugins/monitoring/commands/enable.sh nginx
```

初始化脚本会：
1. 检查并启动 Nginx 服务
2. 配置状态页面
3. 设置监控日志格式
4. 配置日志轮转
5. 检查 SSL 证书

### 2. 配置说明

配置文件位置：`scripts/plugins/monitoring/available/nginx.monitor`

```bash
# 监控设置
CHECK_INTERVAL=60          # 检查间隔（秒）
NGINX_STATUS_PATH="/nginx_status"
NGINX_STATUS_PORT=80
NGINX_CONF_PATH="/etc/nginx/nginx.conf"
NGINX_ACCESS_LOG="/var/log/nginx/access.log"
NGINX_ERROR_LOG="/var/log/nginx/error.log"

# 性能阈值
MAX_ACTIVE_CONNECTIONS=1000    # 最大活动连接数
MAX_WAITING_CONNECTIONS=100    # 最大等待连接数
MAX_REQUEST_RATE=1000         # 每秒最大请求数
MAX_ERROR_RATE=5              # 最大错误率（%）

# 响应时间阈值（毫秒）
MAX_AVG_RESPONSE_TIME=500     # 最大平均响应时间
MAX_P95_RESPONSE_TIME=1000    # 95 百分位响应时间
MAX_P99_RESPONSE_TIME=2000    # 99 百分位响应时间
```

## 监控指标

### 1. 基本状态
- 活动连接数
- 接受的连接数
- 处理的连接数
- 总请求数
- 读取连接数
- 写入连接数
- 等待连接数

### 2. 访问日志分析
- 请求率（每秒请求数）
- 错误率
- 平均响应时间
- 95 百分位响应时间
- 99 百分位响应时间

### 3. 错误日志分析
- 错误数量
- 严重错误数量
- 警告数量
- 紧急错误数量

### 4. SSL 证书状态
- 证书有效期
- 过期警告
- 加密算法检查

### 5. 缓存性能
- 缓存大小
- 缓存命中率
- 缓存使用效率

## 告警规则

### 1. 错误级别告警
- 服务停止运行
- 活动连接数超过阈值
- 错误率超过阈值
- SSL 证书过期
- 严重错误出现

### 2. 警告级别告警
- 等待连接数过高
- 响应时间超过阈值
- 缓存命中率过低
- SSL 证书即将过期
- 普通错误出现

## 监控命令

### 1. 查看状态
```bash
./scripts/plugins/monitoring/commands/status.sh
```

输出示例：
```
Nginx Monitor Status Check
=========================
Time: 2024-01-17 10:30:00

Basic Status:
- Active connections: 100
- Server accepts: 1000
- Server handled: 1000
- Server requests: 2000
- Reading: 10
- Writing: 20
- Waiting: 70

Access Log Analysis:
- Request rate: 50/sec
- Error rate: 0.5%
- Average response time: 200ms
- 95th percentile response time: 500ms
- 99th percentile response time: 800ms

Error Log Analysis:
- Error count: 0
- Critical count: 0
- Alert count: 0
- Emergency count: 0

SSL Certificate:
- Days until expiry: 60

Cache Status:
- Cache size: 2GB
- Cache hit rate: 85%

Status: OK
```

### 2. 禁用监控
```bash
./scripts/plugins/monitoring/commands/disable.sh nginx
```

## 日志说明

### 1. 监控日志
位置：`/var/log/nginx-monitor.log`
- 记录所有监控检查结果
- 包含错误和警告信息
- 性能数据统计

### 2. 访问日志
位置：`/var/log/nginx/access.log`
- 请求详细信息
- 响应时间
- 状态码
- 带宽使用

### 3. 错误日志
位置：`/var/log/nginx/error.log`
- 错误信息
- 配置问题
- 系统问题

## 性能优化建议

### 1. 连接管理
- 调整工作进程数
- 优化 keepalive 设置
- 配置连接缓冲区
- 限制并发连接

### 2. 缓存优化
- 配置合适的缓存大小
- 设置缓存规则
- 监控缓存效率
- 定期清理缓存

### 3. SSL 优化
- 启用 SSL 会话缓存
- 配置 OCSP Stapling
- 使用 HTTP/2
- 优化 SSL 密码套件

## 故障排除

### 1. 服务问题
```bash
# 检查服务状态
systemctl status nginx

# 检查配置语法
nginx -t

# 查看错误日志
tail -f /var/log/nginx/error.log
```

### 2. 性能问题
```bash
# 检查连接状态
curl http://localhost/nginx_status

# 分析访问日志
tail -f /var/log/nginx/access.log

# 检查系统资源
top -p $(pgrep nginx | tr '\n' ',' | sed 's/,$//')
```

### 3. SSL 问题
```bash
# 检查证书有效期
openssl x509 -enddate -noout -in /etc/nginx/ssl/magento.crt

# 测试 SSL 配置
openssl s_client -connect localhost:443
```

## 最佳实践

1. 监控设置
   - 根据系统规模调整阈值
   - 配置合适的检查间隔
   - 设置有效的告警通知
   - 保留足够的历史数据

2. 性能优化
   - 定期分析性能指标
   - 优化配置参数
   - 实施缓存策略
   - 监控资源使用

3. 安全建议
   - 限制状态页面访问
   - 保护监控数据
   - 及时更新 SSL 证书
   - 配置访问控制

4. 日志管理
   - 配置日志轮转
   - 定期分析日志
   - 监控日志大小
   - 备份重要日志 