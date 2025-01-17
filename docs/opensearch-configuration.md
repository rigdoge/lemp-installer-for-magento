# OpenSearch 配置指南

## 功能概述

OpenSearch 是 Magento 2 的默认搜索引擎，本指南包含：
1. 基础配置
2. 安全设置（HTTP 认证）
3. SSL/TLS 加密配置
4. 与 Magento 2 的集成

## 基础配置

### 1. 安装 OpenSearch
```bash
# 使用安装脚本
./scripts/install.sh
```

安装脚本会：
- 添加 OpenSearch 仓库
- 安装 OpenSearch 服务
- 配置基本设置
- 启动服务

### 2. 验证安装
```bash
# 检查服务状态
systemctl status opensearch

# 测试 API
curl -X GET "http://localhost:9200/_cat/nodes?v"
```

### 3. 基础配置文件
配置文件位置：`/etc/opensearch/opensearch.yml`

主要配置项：
```yaml
# 集群设置
cluster.name: magento-opensearch
node.name: ${HOSTNAME}

# 网络设置
network.host: localhost
http.port: 9200

# 内存设置
bootstrap.memory_lock: true

# 路径配置
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch
```

## HTTP 基本认证

### 1. 配置认证
```bash
# 使用配置脚本
./scripts/configure_opensearch_auth.sh <username> <password>
```

### 2. 验证配置
```bash
# 测试认证
curl -X GET "http://localhost:9200/_cat/nodes?v" -u "username:password"
```

### 3. Magento 2 配置
1. 进入管理后台：Stores > Configuration > Catalog > Catalog > Catalog Search
2. 更新以下设置：
   - OpenSearch Server Hostname: localhost
   - OpenSearch Server Port: 9200
   - Enable OpenSearch HTTP Auth: Yes
   - OpenSearch HTTP Auth Username: 配置的用户名
   - OpenSearch HTTP Auth Password: 配置的密码
3. 保存配置并清除缓存

## SSL/TLS 配置

### 1. 生成证书
```bash
# 使用配置脚本
./scripts/configure_opensearch_ssl.sh
```

脚本会生成：
- 根证书 (root-ca.pem)
- 管理员证书 (admin.pem)
- 节点证书 (node.pem)

### 2. 配置 SSL
配置文件更新：
```yaml
# SSL 设置
plugins.security.ssl.transport.enabled: true
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: certificates/node.pem
plugins.security.ssl.http.pemkey_filepath: certificates/node-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: certificates/root-ca.pem
```

### 3. 验证 SSL 配置
```bash
# 测试 SSL 连接
curl -k -X GET "https://localhost:9200/_cat/nodes?v" \
  --cert certificates/admin.pem \
  --key certificates/admin-key.pem \
  --cacert certificates/root-ca.pem
```

### 4. Magento 2 SSL 配置
1. 进入管理后台配置
2. 更新以下设置：
   - OpenSearch Server Hostname: https://localhost
   - OpenSearch Server Port: 9200
   - Enable OpenSearch SSL: Yes
   - SSL Certificate Path: 证书路径
3. 保存并清除缓存

## 性能优化

### 1. JVM 设置
编辑 `/etc/opensearch/jvm.options`：
```
-Xms2g
-Xmx2g
```

### 2. 系统设置
编辑 `/etc/sysctl.conf`：
```
vm.max_map_count=262144
```

### 3. 索引设置
```json
{
  "index": {
    "number_of_shards": 5,
    "number_of_replicas": 1
  }
}
```

## 维护操作

### 1. 索引管理
```bash
# 列出所有索引
curl -X GET "localhost:9200/_cat/indices?v"

# 优化索引
curl -X POST "localhost:9200/index_name/_forcemerge"
```

### 2. 备份恢复
```bash
# 创建快照
curl -X PUT "localhost:9200/_snapshot/backup/snapshot_1"

# 恢复快照
curl -X POST "localhost:9200/_snapshot/backup/snapshot_1/_restore"
```

## 故障排除

### 1. 服务问题
```bash
# 检查服务状态
systemctl status opensearch

# 查看日志
tail -f /var/log/opensearch/magento-opensearch.log
```

### 2. 连接问题
```bash
# 测试连接
curl -I http://localhost:9200

# 检查防火墙
sudo ufw status
```

### 3. 认证问题
```bash
# 重置用户
./scripts/configure_opensearch_auth.sh --reset

# 验证权限
curl -u "username:password" http://localhost:9200/_cat/indices
```

### 4. SSL 问题
```bash
# 重新生成证书
./scripts/configure_opensearch_ssl.sh --regenerate

# 验证证书
openssl verify -CAfile certificates/root-ca.pem certificates/node.pem
```

## 安全建议

1. 访问控制
   - 使用强密码
   - 定期轮换证书
   - 限制 IP 访问

2. 网络安全
   - 启用 SSL/TLS
   - 配置防火墙
   - 监控异常访问

3. 数据安全
   - 定期备份
   - 加密敏感数据
   - 实施审计日志 