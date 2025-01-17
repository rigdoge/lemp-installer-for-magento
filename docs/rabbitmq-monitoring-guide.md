# RabbitMQ 监控指南

## 监控方式概述

RabbitMQ 监控系统提供两种监控方式：
1. 命令行监控（使用监控脚本）
2. Web 界面监控（使用 RabbitMQ Management UI）

## 1. 命令行监控

### 安装和配置

1. 安装必要组件：
```bash
# Ubuntu/Debian
sudo apt-get install supervisor

# CentOS/RHEL
sudo yum install supervisor

# macOS
brew install supervisor
```

2. 启用监控：
```bash
./scripts/plugins/monitoring/commands/enable.sh rabbitmq
```

### 使用监控命令

1. 查看监控状态：
```bash
./scripts/plugins/monitoring/commands/status.sh
```

2. 禁用监控：
```bash
./scripts/plugins/monitoring/commands/disable.sh rabbitmq
```

### 监控指标说明

监控脚本检查以下指标：
- 服务运行状态
- 队列数量和状态
- 消息积压情况
- 消费者状态
- 内存使用情况

### 状态码说明
- 0: 正常
- 1: 错误（如服务停止、无消费者）
- 2: 警告（如消息积压、内存使用过高）

### 日志查看
```bash
# 查看 RabbitMQ 日志
tail -f /var/log/rabbitmq/rabbit@hostname.log

# 查看监控日志
tail -f /var/log/rabbitmq-monitor.log
```

## 2. Web 界面监控

### 访问方式
- URL: http://服务器IP:15672
- 默认监控账号：
  - 用户名：monitor
  - 密码：monitor_password

### 主要功能区域

1. Overview（概览）
   - 查看节点状态
   - 消息率统计
   - 全局统计信息

2. Connections（连接）
   - 当前连接列表
   - 连接详细信息
   - 连接状态

3. Channels（通道）
   - 活动通道
   - 通道统计
   - 消费者信息

4. Exchanges（交换机）
   - 交换机列表
   - 绑定关系
   - 消息流转情况

5. Queues（队列）
   - 队列状态
   - 消息统计
   - 内存使用
   - 消费者信息

6. Admin（管理）
   - 用户管理
   - 权限设置
   - 策略配置

### 监控指标详解

1. 队列监控
   - 队列深度（消息数量）
   - 消费者数量
   - 消息处理速率
   - 内存使用情况

2. 系统监控
   - CPU 使用率
   - 内存使用率
   - 磁盘空间
   - 文件描述符使用情况

3. 连接监控
   - 连接数量
   - 通道数量
   - 网络流量

### 告警阈值设置

在配置文件中设置告警阈值：
```bash
# 编辑配置文件
vim scripts/plugins/monitoring/available/rabbitmq.monitor

# 常用配置项
MAX_QUEUE_SIZE=1000        # 队列最大消息数
MIN_CONSUMERS=1            # 最小消费者数
MAX_MEMORY_USAGE=0.8       # 最大内存使用率
```

## 最佳实践

### 日常监控建议
1. 定期查看监控状态
2. 关注队列积压情况
3. 检查消费者状态
4. 监控内存使用

### 告警处理流程
1. 收到告警后立即检查日志
2. 确认问题类型和严重程度
3. 按照问题类型采取相应措施
4. 记录处理过程和结果

### 性能优化建议
1. 及时处理消息积压
2. 保持适当的消费者数量
3. 定期清理无用队列
4. 监控并优化内存使用

## 故障排除

### 常见问题

1. 服务无法启动
```bash
# 检查服务状态
systemctl status rabbitmq-server

# 查看错误日志
tail -f /var/log/rabbitmq/rabbit@hostname.log
```

2. 监控用户访问失败
```bash
# 重置监控用户
rabbitmqctl delete_user monitor
rabbitmqctl add_user monitor monitor_password
rabbitmqctl set_user_tags monitor monitoring
```

3. 队列积压处理
```bash
# 检查消费者状态
rabbitmqctl list_consumers

# 重启消费者
bin/magento queue:consumers:start --all
```

### 紧急情况处理
1. 服务重启：
```bash
systemctl restart rabbitmq-server
```

2. 清理队列：
```bash
rabbitmqctl purge_queue queue_name
```

3. 重置监控：
```bash
./scripts/plugins/monitoring/commands/disable.sh rabbitmq
./scripts/plugins/monitoring/commands/enable.sh rabbitmq
``` 