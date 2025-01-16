#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查参数
if [ "$#" -ne 2 ]; then
    error "Usage: $0 <username> <password>"
fi

USERNAME="$1"
PASSWORD="$2"

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 检查 OpenSearch 是否安装
if ! systemctl is-active --quiet opensearch; then
    error "OpenSearch is not running. Please install and start OpenSearch first."
fi

# 创建内部用户配置目录
CONFIG_DIR="/usr/local/opensearch/config"
mkdir -p "$CONFIG_DIR"

# 生成内部用户配置文件
log "Generating internal users configuration..."
cat > "$CONFIG_DIR/internal_users.yml" <<EOF
_meta:
  type: "internalusers"
  config_version: 2

# 定义用户
$USERNAME:
  hash: "$(echo -n "$PASSWORD" | openssl dgst -sha512 | awk '{print $2}')"
  reserved: false
  backend_roles:
  - "admin"
  description: "Admin user"
EOF

# 更新 OpenSearch 配置
log "Updating OpenSearch configuration..."
cat > "$CONFIG_DIR/opensearch.yml" <<EOF
cluster.name: magento-cluster
node.name: magento-node
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node

# 安全配置
plugins.security.disabled: false
plugins.security.ssl.http.enabled: false
plugins.security.allow_default_init_securityindex: true
plugins.security.authcz.admin_dn:
  - "CN=admin"
plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]

# 角色映射
plugins.security.roles_mapping.all_access:
  backend_roles:
  - "admin"
  hosts: []
  users:
  - "$USERNAME"
EOF

# 设置权限
chown -R opensearch:opensearch "$CONFIG_DIR"
chmod 600 "$CONFIG_DIR/internal_users.yml"
chmod 600 "$CONFIG_DIR/opensearch.yml"

# 重启 OpenSearch
log "Restarting OpenSearch..."
systemctl restart opensearch

# 等待服务启动
log "Waiting for OpenSearch to start..."
sleep 30

# 测试连接
log "Testing connection..."
curl -X GET "http://localhost:9200/_cat/nodes?v" -u "$USERNAME:$PASSWORD"

log "OpenSearch HTTP authentication configuration completed!"
log "To connect to OpenSearch, use the following credentials:"
log "Username: $USERNAME"
log "Password: $PASSWORD"
log "Example curl command:"
log "curl -X GET \"http://localhost:9200/_cat/nodes?v\" -u \"$USERNAME:$PASSWORD\""

warn "Please make sure to update your Magento configuration with these credentials." 