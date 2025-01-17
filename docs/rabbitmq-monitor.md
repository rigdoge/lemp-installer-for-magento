# RabbitMQ 监控模块

## 功能概述

RabbitMQ 监控模块用于监控 Magento 2 环境中的消息队列系统，提供实时状态监控和告警功能。

## 主要功能

1. 服务状态监控
   - 服务运行状态
   - 内存使用情况
   - 连接状态

2. 队列监控
   - 队列数量
   - 消息积压情况
   - 消费者状态

3. Magento 特定队列监控
   - 异步操作队列
   - 库存更新队列
   - 产品属性更新队列

## 配置说明

### 基础配置

配置文件位置：`scripts/plugins/monitoring/available/rabbitmq.monitor`

```bash
# 监控设置
CHECK_INTERVAL=300          # 检查间隔（秒）
MAX_QUEUE_SIZE=1000        # 队列最大消息数
MIN_CONSUMERS=1            # 最小消费者数
MAX_MEMORY_USAGE=0.8       # 最大内存使用率
```

### 告警阈值

```bash
ALERT_THRESHOLD=3          # 连续失败次数阈值
ALERT_EMAIL="admin@example.com"
```

### Magento 队列配置

```bash
MAGENTO_QUEUES=(
    "async.operations.all"
    "inventory.source.items.cleanup"
    # ... 其他队列
)
```

## 安装和使用

### 1. 启用监控

```bash
./scripts/plugins/monitoring/commands/enable.sh rabbitmq
```

### 2. 检查状态

```bash
./scripts/plugins/monitoring/commands/status.sh
```

### 3. 禁用监控

```bash
./scripts/plugins/monitoring/commands/disable.sh rabbitmq
```

## 监控指标

### 1. 服务健康状态
- 服务运行状态
- 内存使用情况
- 连接数

### 2. 队列状态
- 总队列数
- 每个队列的消息数
- 活动消费者数

### 3. 性能指标
- 消息处理速率
- 消费者响应时间
- 内存使用趋势

## 告警规则

1. 错误级别告警：
   - 服务停止运行
   - 队列无消费者
   - 内存使用超过阈值

2. 警告级别告警：
   - 消息积压超过阈值
   - 消费者数量不足
   - 处理速度异常

## 日志说明

### 日志位置
```bash
LOG_FILE="/var/log/rabbitmq-monitor.log"
```

### 日志格式
```
[时间戳] [级别] 消息内容
状态详情
```

### 日志轮转
- 最大大小：10MB
- 保留天数：7天

## 故障排除

### 1. 服务无法启动
```bash
# 检查服务状态
systemctl status rabbitmq-server

# 检查日志
tail -f /var/log/rabbitmq/rabbit@hostname.log
```

### 2. 监控用户访问失败
```bash
# 重置监控用户
rabbitmqctl delete_user monitor
rabbitmqctl add_user monitor monitor_password
rabbitmqctl set_user_tags monitor monitoring
```

### 3. 队列积压
```bash
# 检查消费者状态
rabbitmqctl list_consumers

# 重启消费者
bin/magento queue:consumers:start --all
```

## 最佳实践

1. 监控配置
   - 根据系统规模调整阈值
   - 定期检查告警设置
   - 及时更新监控配置

2. 告警处理
   - 建立告警响应流程
   - 记录处理过程
   - 定期review告警历史

3. 维护建议
   - 定期检查日志
   - 更新监控脚本
   - 备份监控配置

## 安全注意事项

1. 访问控制
   - 限制监控用户权限
   - 定期更改密码
   - 使用加密连接

2. 数据安全
   - 保护配置文件
   - 加密敏感信息
   - 限制日志访问

3. 系统安全
   - 及时更新组件
   - 监控异常访问
   - 定期安全审计 