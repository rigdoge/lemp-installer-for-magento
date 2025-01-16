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

# 检查并安装 Java
log "Checking Java installation..."
if ! command -v java &> /dev/null; then
    log "Java not found. Installing OpenJDK 17..."
    apt-get update
    apt-get install -y openjdk-17-jdk
fi

# 验证 Java 安装
JAVA_VERSION=$(java -version 2>&1 | head -n 1)
if [[ $? -ne 0 ]]; then
    error "Failed to verify Java installation"
fi
log "Java installation verified: $JAVA_VERSION"

# 设置 Java 环境变量
if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
    export OPENSEARCH_JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
    log "Java environment variables set: JAVA_HOME=$JAVA_HOME"
else
    warn "OpenJDK 17 directory not found at expected location"
    # 尝试查找 Java 安装位置
    JAVA_PATH=$(readlink -f $(which java))
    JAVA_HOME=${JAVA_PATH%/bin/java}
    if [ -n "$JAVA_HOME" ]; then
        export JAVA_HOME=$JAVA_HOME
        export OPENSEARCH_JAVA_HOME=$JAVA_HOME
        log "Java environment variables set using found path: JAVA_HOME=$JAVA_HOME"
    else
        error "Could not determine Java installation path"
    fi
fi

# 检查 OpenSearch 是否安装
if ! systemctl is-active --quiet opensearch; then
    error "OpenSearch is not running. Please install and start OpenSearch first."
fi

# 停止 OpenSearch 服务
log "Stopping OpenSearch service..."
systemctl stop opensearch

# 清理旧的配置和证书
log "Cleaning up old configurations and certificates..."
# 删除安全配置目录
if [ -d "/usr/local/opensearch/config/opensearch-security" ]; then
    rm -rf "/usr/local/opensearch/config/opensearch-security"
    log "Removed old security configuration directory"
fi

# 删除证书目录
if [ -d "/usr/local/opensearch/config/certificates" ]; then
    rm -rf "/usr/local/opensearch/config/certificates"
    log "Removed old certificates directory"
fi

# 删除主配置文件
if [ -f "/usr/local/opensearch/config/opensearch.yml" ]; then
    rm -f "/usr/local/opensearch/config/opensearch.yml"
    log "Removed old opensearch.yml configuration"
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

# 先禁用安全插件以初始化配置
log "Temporarily disabling security plugin for initialization..."
sed -i 's/plugins.security.disabled: false/plugins.security.disabled: true/' "$CONFIG_DIR/opensearch.yml"

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

# 基本配置
bootstrap.memory_lock: false
plugins.query.datasources.encryption.masterkey: "magento-master-key-123"

# 自动导入悬空索引
gateway.auto_import_dangling_indices: true

# 安全配置
plugins.security.disabled: false
plugins.security.ssl.transport.enabled: true
plugins.security.ssl.transport.pemcert_filepath: certificates/node.pem
plugins.security.ssl.transport.pemkey_filepath: certificates/node-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: certificates/root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: certificates/node.pem
plugins.security.ssl.http.pemkey_filepath: certificates/node-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: certificates/root-ca.pem
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.allow_default_init_securityindex: true
plugins.security.authcz.admin_dn:
  - "CN=node,OU=Example Com Unit,O=Example Com,L=Shanghai,ST=Shanghai,C=CN"
plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]

# 配置覆盖设置
plugins.plugin_name.config_overrides.enabled: true
EOF

# 设置权限
chown -R opensearch:opensearch "$CONFIG_DIR"
chmod 600 "$CONFIG_DIR/opensearch.yml"

# 生成默认安全配置
log "Generating default security configuration..."
cp -r /usr/local/opensearch/plugins/opensearch-security/securityconfig/* "$SECURITY_CONFIG_DIR/"
chown -R opensearch:opensearch "$SECURITY_CONFIG_DIR"
chmod 600 "$SECURITY_CONFIG_DIR"/*

# 重启 OpenSearch 使配置生效
log "Restarting OpenSearch with SSL configuration..."
systemctl restart opensearch

# 等待服务启动
log "Waiting for OpenSearch to start..."
for i in {1..60}; do
    if systemctl is-active --quiet opensearch; then
        log "OpenSearch service is running"
        sleep 10  # 给予额外时间让 SSL 配置生效
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# 运行 securityadmin.sh 来初始化安全配置
log "Running security initialization..."
cd "$SECURITY_TOOLS_DIR"
./securityadmin.sh -cd "$SECURITY_CONFIG_DIR" \
    -icl -nhnv \
    -cacert "$CERT_DIR/root-ca.pem" \
    -cert "$CERT_DIR/node.pem" \
    -key "$CERT_DIR/node-key.pem" \
    -h localhost \
    -p 9200

# 返回原目录
cd -

# 验证节点是否正常运行
log "Verifying node status..."
sleep 5  # 给予系统一些时间来应用更改
NODE_COUNT=$(curl -s -k -u "admin:admin" "https://localhost:9200/_cat/nodes?h=ip" | wc -l)
if [ "$NODE_COUNT" -eq 0 ]; then
    error "No alive nodes found in the cluster. Please check OpenSearch configuration."
fi

# 创建新用户
log "Creating user..."
curl -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/$USERNAME" \
    -H 'Content-Type: application/json' \
    -k -u "admin:admin" \
    -d "{
  \"password\": \"$PASSWORD\",
  \"backend_roles\": [\"admin\"],
  \"attributes\": {}
}"

# 等待用户创建完成
sleep 5

# 验证用户创建是否成功
log "Verifying user creation..."
RESPONSE=$(curl -s -k -w "%{http_code}" -o /dev/null -u "$USERNAME:$PASSWORD" "https://localhost:9200/_cat/nodes?v")
if [ "$RESPONSE" = "200" ]; then
    log "User verification successful!"
else
    warn "User verification failed with status code: $RESPONSE"
    warn "Checking with admin credentials..."
    curl -v -k -u "admin:admin" "https://localhost:9200/_plugins/_security/api/internalusers/$USERNAME"
fi

# 测试连接
log "Testing connection..."
curl -X GET "https://localhost:9200/_cat/nodes?v" -k -u "$USERNAME:$PASSWORD"

log "OpenSearch HTTPS authentication configuration completed!"
log "To connect to OpenSearch, use the following credentials:"
log "Username: $USERNAME"
log "Password: $PASSWORD"
log "Example curl command:"
log "curl -X GET \"https://localhost:9200/_cat/nodes?v\" -k -u \"$USERNAME:$PASSWORD\""

warn "Please make sure to update your Magento configuration with these credentials." 