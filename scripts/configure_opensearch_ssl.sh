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

# 清理旧的证书和配置
log "Cleaning up old SSL certificates and configuration..."
CERT_DIR="/usr/local/opensearch/config/certificates"
if [ -d "$CERT_DIR" ]; then
    rm -rf "$CERT_DIR"
    log "Removed old certificates directory"
fi

# 创建内部用户配置目录
CONFIG_DIR="/usr/local/opensearch/config"
SECURITY_CONFIG_DIR="$CONFIG_DIR/opensearch-security"
mkdir -p "$CONFIG_DIR" "$SECURITY_CONFIG_DIR"

# 备份现有配置
if [ -f "$CONFIG_DIR/opensearch.yml" ]; then
    cp "$CONFIG_DIR/opensearch.yml" "$CONFIG_DIR/opensearch.yml.bak"
    log "Backed up existing OpenSearch configuration"
fi

# 检查并创建日志目录
log "Checking log directory..."
LOG_DIR="/var/log/opensearch"
mkdir -p "$LOG_DIR"
chown opensearch:opensearch "$LOG_DIR"
chmod 750 "$LOG_DIR"

# 创建证书目录
log "Creating certificates directory..."
CERT_DIR="/usr/local/opensearch/config/certificates"
mkdir -p "$CERT_DIR"

# 生成根证书
log "Generating root certificate..."
openssl genrsa -out "$CERT_DIR/root-ca-key.pem" 2048
openssl req -new -x509 -sha256 -key "$CERT_DIR/root-ca-key.pem" -out "$CERT_DIR/root-ca.pem" -days 730 -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Example Com/OU=Example Com Unit/CN=root-ca"

# 生成节点证书
log "Generating node certificate..."
openssl genrsa -out "$CERT_DIR/node-key.pem" 2048
openssl req -new -key "$CERT_DIR/node-key.pem" -out "$CERT_DIR/node.csr" -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Example Com/OU=Example Com Unit/CN=node"
openssl x509 -req -in "$CERT_DIR/node.csr" -CA "$CERT_DIR/root-ca.pem" -CAkey "$CERT_DIR/root-ca-key.pem" -CAcreateserial -sha256 -out "$CERT_DIR/node.pem" -days 730

# 设置证书权限
chown -R opensearch:opensearch "$CERT_DIR"
chmod 600 "$CERT_DIR"/*

# 初始化安全插件
log "Initializing security plugin..."
SECURITY_TOOLS_DIR="/usr/local/opensearch/plugins/opensearch-security/tools"

# 确保工具目录存在
if [ ! -d "$SECURITY_TOOLS_DIR" ]; then
    error "Security plugin tools directory not found at $SECURITY_TOOLS_DIR"
fi

cd "$SECURITY_TOOLS_DIR"

# 确保 securityadmin.sh 有执行权限
log "Setting permissions for security tools..."
chmod +x securityadmin.sh

# 运行 securityadmin.sh 来初始化安全配置
./securityadmin.sh -cd "$SECURITY_CONFIG_DIR" \
    -icl -nhnv \
    -cacert "$CERT_DIR/root-ca.pem" \
    -cert "$CERT_DIR/node.pem" \
    -key "$CERT_DIR/node-key.pem" \
    -h localhost

# 返回原目录
cd -

# 设置 Java 环境
log "Setting up Java environment..."
export OPENSEARCH_JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

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

# 先禁用安全插件
plugins.security.disabled: true

# JVM 配置
bootstrap.memory_lock: false
EOF

# 设置权限
chown -R opensearch:opensearch "$CONFIG_DIR"
chmod 600 "$CONFIG_DIR/opensearch.yml"

# 重启 OpenSearch 并等待初始化完成
log "Restarting OpenSearch..."
systemctl restart opensearch

# 等待服务启动并检查状态
log "Waiting for OpenSearch to start..."
for i in {1..60}; do
    if curl -s "http://localhost:9200/_cluster/health" | grep -q '"status":\s*"green"'; then
        log "OpenSearch started successfully without security"
        break
    fi
    if [ $i -eq 5 ]; then
        log "Checking OpenSearch logs..."
        tail -n 50 /var/log/opensearch/magento-cluster.log || true
        log "Checking OpenSearch status..."
        systemctl status opensearch || true
    fi
    if [ $i -eq 60 ]; then
        error "OpenSearch failed to start. Please check the logs."
    fi
    echo -n "."
    sleep 2
done
echo ""

# 验证节点是否正常运行
log "Verifying node status..."
NODE_COUNT=$(curl -s "http://localhost:9200/_cat/nodes?h=ip" | wc -l)
if [ "$NODE_COUNT" -eq 0 ]; then
    error "No alive nodes found in the cluster. Please check OpenSearch configuration."
fi

# 生成配置文件
log "Generating configuration files..."
cat > "$SECURITY_CONFIG_DIR/config.yml" <<EOF
_meta:
  type: "config"
  config_version: 2

config:
  dynamic:
    http:
      anonymous_auth_enabled: false
      xff:
        enabled: false
    authc:
      basic_internal_auth_domain:
        description: "Authenticate via HTTP Basic against internal users database"
        http_enabled: true
        transport_enabled: true
        order: 0
        http_authenticator:
          type: basic
          challenge: false
        authentication_backend:
          type: intern
EOF

cat > "$SECURITY_CONFIG_DIR/action_groups.yml" <<EOF
_meta:
  type: "actiongroups"
  config_version: 2

admin_all:
  reserved: true
  hidden: false
  allowed_actions:
    - "*"
EOF

# 生成内部用户配置
log "Generating internal users configuration..."
cat > "$SECURITY_CONFIG_DIR/internal_users.yml" <<EOF
_meta:
  type: "internalusers"
  config_version: 2

# 默认管理员用户
admin:
  hash: "\$2a\$12\$VcCDgh2NDk07JGN0rjGbM.Ad41qVR/YFJcgHp0UGns5JDymv..TOG"  # admin
  reserved: true
  backend_roles:
  - "admin"
  description: "Admin user"

# Magento 用户
$USERNAME:
  hash: "\$2a\$12\$VcCDgh2NDk07JGN0rjGbM.Ad41qVR/YFJcgHp0UGns5JDymv..TOG"  # 临时使用相同密码
  reserved: false
  backend_roles:
  - "admin"
  description: "Magento admin user"
EOF

# 生成角色配置
log "Generating roles configuration..."
cat > "$SECURITY_CONFIG_DIR/roles.yml" <<EOF
_meta:
  type: "roles"
  config_version: 2

# 管理员角色
admin_role:
  reserved: true
  hidden: false
  cluster_permissions:
  - "unlimited"
  index_permissions:
  - index_patterns:
    - "*"
    allowed_actions:
    - "unlimited"
  tenant_permissions:
  - tenant_patterns:
    - "*"
    allowed_actions:
    - "unlimited"

# Magento 角色
magento_role:
  reserved: false
  hidden: false
  cluster_permissions:
  - "cluster:monitor/main"
  - "cluster:monitor/health"
  index_permissions:
  - index_patterns:
    - "magento*"
    allowed_actions:
    - "read"
    - "write"
    - "delete"
    - "create_index"
EOF

# 生成角色映射配置
log "Generating roles mapping configuration..."
cat > "$SECURITY_CONFIG_DIR/roles_mapping.yml" <<EOF
_meta:
  type: "rolesmapping"
  config_version: 2

# 管理员角色映射
admin_role:
  reserved: true
  hidden: false
  backend_roles:
  - "admin"
  hosts: []
  users:
  - "admin"
  - "$USERNAME"

# Magento 角色映射
magento_role:
  reserved: false
  hidden: false
  backend_roles:
  - "admin"
  hosts: []
  users:
  - "$USERNAME"
EOF

# 设置权限
chown -R opensearch:opensearch "$SECURITY_CONFIG_DIR"
chmod 600 "$SECURITY_CONFIG_DIR"/*

# 启用安全插件
log "Enabling security plugin..."
cat >> "$CONFIG_DIR/opensearch.yml" <<EOF

# 安全配置
plugins.security.ssl.transport.pemcert_filepath: certificates/node.pem
plugins.security.ssl.transport.pemkey_filepath: certificates/node-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: certificates/root-ca.pem
plugins.security.ssl.http.enabled: false
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.allow_default_init_securityindex: true
plugins.security.authcz.admin_dn:
  - "CN=node,OU=Example Com Unit,O=Example Com,L=Shanghai,ST=Shanghai,C=CN"
plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
plugins.security.disabled: false
EOF

# 创建新用户
log "Creating user..."
curl -X PUT "http://localhost:9200/_plugins/_security/api/internalusers/$USERNAME" \
    -H 'Content-Type: application/json' \
    -u "admin:admin" \
    -d "{
  \"password\": \"$PASSWORD\",
  \"backend_roles\": [\"admin\"],
  \"attributes\": {}
}"

# 等待用户创建完成
sleep 5

# 验证用户创建是否成功
log "Verifying user creation..."
RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -u "$USERNAME:$PASSWORD" "http://localhost:9200/_cat/nodes?v")
if [ "$RESPONSE" = "200" ]; then
    log "User verification successful!"
else
    warn "User verification failed with status code: $RESPONSE"
    warn "Checking with admin credentials..."
    curl -v -u "admin:admin" "http://localhost:9200/_plugins/_security/api/internalusers/$USERNAME"
fi

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