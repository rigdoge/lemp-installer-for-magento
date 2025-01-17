# OpenSearch 用户管理

本文档介绍如何使用 `configure_opensearch_ssl.sh` 脚本管理 OpenSearch 用户。

## 功能特性

- SSL 证书配置
- 用户创建
- 用户删除
- 配置验证

## 使用方法

### 1. 创建新用户

```bash
sudo ./scripts/configure_opensearch_ssl.sh <username> <password>
```

示例：
```bash
sudo ./scripts/configure_opensearch_ssl.sh magento password123
```

### 2. 删除用户

```bash
sudo ./scripts/configure_opensearch_ssl.sh <username> <password> delete
```

示例：
```bash
sudo ./scripts/configure_opensearch_ssl.sh magento password123 delete
```

### 3. 验证用户

创建用户后，可以使用以下命令测试连接：
```bash
curl -k "https://localhost:9200/_cat/nodes?v" -u "username:password"
```

## 注意事项

1. 必须以 root 用户或使用 sudo 运行脚本
2. OpenSearch 服务必须正在运行
3. 创建用户时会自动配置必要的安全设置
4. 默认为用户分配 admin 和 all_access 角色
5. 证书和配置文件存储在 `/usr/local/opensearch/config/` 目录下

## 常见问题

### 1. 服务未运行

如果遇到服务未运行的错误，请执行：
```bash
sudo systemctl start opensearch
```

### 2. 权限问题

确保使用 sudo 运行脚本：
```bash
sudo ./scripts/configure_opensearch_ssl.sh ...
```

### 3. 连接失败

如果无法连接，请检查：
- OpenSearch 服务状态
- 用户名和密码是否正确
- SSL 证书配置

## 配置文件位置

- 证书目录：`/usr/local/opensearch/config/certificates/`
- 配置文件：`/usr/local/opensearch/config/opensearch.yml`
- 安全配置：`/usr/local/opensearch/config/opensearch-security/`

## 日志文件

主要日志文件位置：
```
/var/log/opensearch/magento-cluster.log
```

## 安全建议

1. 定期更改密码
2. 删除不再使用的用户账号
3. 保持证书的安全存储
4. 定期备份配置文件 