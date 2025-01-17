# OpenSearch 监控指南

## 功能概述

OpenSearch 监控模块提供以下功能：
1. 集群健康状态监控
2. 节点资源使用监控
3. 索引状态和性能监控
4. 查询性能监控
5. 快照备份监控

## 安装和配置

### 1. 启用监控

```bash
./scripts/plugins/monitoring/commands/enable.sh opensearch
```

初始化脚本会：
1. 检查并启动 OpenSearch 服务
2. 创建专用监控用户和角色
3. 配置快照仓库
4. 设置监控日志

### 2. 配置说明

配置文件位置：`scripts/plugins/monitoring/available/opensearch.monitor`

```bash
# 监控设置
CHECK_INTERVAL=60          # 检查间隔（秒）
OPENSEARCH_HOST="localhost"
OPENSEARCH_PORT=9200
OPENSEARCH_USER="admin"
OPENSEARCH_PASS="admin"
OPENSEARCH_USE_SSL=true

# 性能阈值
MAX_CPU_USAGE=90          # 最大 CPU 使用率（%）
MAX_MEMORY_USAGE=90       # 最大内存使用率（%）
MAX_DISK_USAGE=90         # 最大磁盘使用率（%）
MAX_HEAP_USAGE=80         # 最大堆内存使用率（%）

# 集群设置
MIN_ACTIVE_SHARDS=90      # 最小活动分片百分比
MAX_INITIALIZING_SHARDS=5 # 最大初始化分片数
MAX_RELOCATING_SHARDS=5   # 最大重定位分片数
MAX_UNASSIGNED_SHARDS=5   # 最大未分配分片数
```

## 监控指标

### 1. 集群健康状态
- 集群状态（绿色/黄色/红色）
- 活动分片百分比
- 初始化分片数
- 重定位分片数
- 未分配分片数

### 2. 节点状态
- CPU 使用率
- 堆内存使用率
- 磁盘使用率
- JVM 状态

### 3. 索引状态
- 索引健康状态
- 索引大小
- 文档数量
- 分片分布

### 4. 查询性能
- 搜索延迟
- 索引延迟
- 查询吞吐量
- 慢查询统计

## 告警规则

### 1. 错误级别告警
- 集群状态为红色
- 内存使用超过阈值
- 磁盘使用超过阈值
- 未分配分片过多

### 2. 警告级别告警
- 集群状态为黄色
- 资源使用接近阈值
- 查询延迟过高
- 索引性能下降

## 监控命令

### 1. 查看状态
```bash
./scripts/plugins/monitoring/commands/status.sh
```

输出示例：
```
OpenSearch Monitor Status Check
==============================
Time: 2024-01-17 10:30:00

Cluster Health:
- Status: green
- Active shards: 100%
- Initializing shards: 0
- Relocating shards: 0
- Unassigned shards: 0

Node Status:
- CPU Usage: 45%
- Heap Usage: 60%
- Disk Usage: 55%

Index Status:
- Index: magento2_product_1
  Status: green
  Size: 20GB
  Documents: 1000000

Query Performance:
- Search Latency: 200ms
- Indexing Latency: 150ms

Status: OK
```

### 2. 禁用监控
```bash
./scripts/plugins/monitoring/commands/disable.sh opensearch
```

## 日志说明

### 1. 监控日志
位置：`/var/log/opensearch-monitor.log`
- 记录所有监控检查结果
- 包含错误和警告信息
- 性能数据统计

### 2. OpenSearch 日志
位置：`/var/log/opensearch/opensearch.log`
- OpenSearch 服务日志
- 系统错误和警告
- 性能问题追踪

## 性能优化建议

### 1. 集群管理
- 定期检查分片分布
- 优化副本数量
- 合理设置分片大小
- 监控集群扩展需求

### 2. 内存管理
- 调整 JVM 堆大小
- 监控垃圾回收
- 优化缓存设置
- 防止内存泄漏

### 3. 索引优化
- 定期合并段
- 设置合理的刷新间隔
- 优化映射设置
- 实施索引生命周期管理

## 故障排除

### 1. 集群问题
```bash
# 检查集群健康
curl -k -u "monitor:monitor_password" \
    "https://localhost:9200/_cluster/health?pretty"

# 查看未分配分片
curl -k -u "monitor:monitor_password" \
    "https://localhost:9200/_cat/shards?h=index,shard,prirep,state,unassigned.reason"
```

### 2. 性能问题
```bash
# 检查热点线程
curl -k -u "monitor:monitor_password" \
    "https://localhost:9200/_nodes/hot_threads"

# 查看节点统计
curl -k -u "monitor:monitor_password" \
    "https://localhost:9200/_nodes/stats"
```

### 3. 索引问题
```bash
# 检查索引设置
curl -k -u "monitor:monitor_password" \
    "https://localhost:9200/_settings"

# 查看索引统计
curl -k -u "monitor:monitor_password" \
    "https://localhost:9200/_stats"
```

## 最佳实践

1. 监控设置
   - 根据系统规模调整阈值
   - 配置合适的检查间隔
   - 设置有效的告警通知
   - 保留足够的历史数据

2. 性能优化
   - 定期分析性能指标
   - 优化查询模式
   - 调整系统参数
   - 实施预防性维护

3. 安全建议
   - 定期更新监控用户密码
   - 限制监控 API 访问
   - 加密监控数据
   - 审计监控操作

4. 备份策略
   - 配置定期快照
   - 验证备份完整性
   - 测试恢复流程
   - 维护备份历史 