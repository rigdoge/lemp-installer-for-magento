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

# 检查 OpenSearch 是否已安装并运行
if ! systemctl is-active --quiet opensearch; then
    error "OpenSearch is not running. Please install and start OpenSearch first."
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

CONFIG_DIR="/usr/local/opensearch/config"
CERT_DIR="$CONFIG_DIR/certificates"
SECURITY_CONFIG_DIR="$CONFIG_DIR/opensearch-security"

# 如果证书不存在，则创建证书
if [ ! -f "$CERT_DIR/node.pem" ]; then
    log "Certificates not found. Generating new certificates..."
    
    # 创建证书目录
    mkdir -p "$CERT_DIR"
    
    # 生成根证书
    openssl genrsa -out "$CERT_DIR/root-ca-key.pem" 2048
    openssl req -new -x509 -sha256 -key "$CERT_DIR/root-ca-key.pem" -out "$CERT_DIR/root-ca.pem" -days 730 -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Example Com/OU=Example Com Unit/CN=root-ca"
    
    # 生成节点证书
    openssl genrsa -out "$CERT_DIR/node-key.pem" 2048
    openssl req -new -key "$CERT_DIR/node-key.pem" -out "$CERT_DIR/node.csr" -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Example Com/OU=Example Com Unit/CN=node"
    openssl x509 -req -in "$CERT_DIR/node.csr" -CA "$CERT_DIR/root-ca.pem" -CAkey "$CERT_DIR/root-ca-key.pem" -CAcreateserial -sha256 -out "$CERT_DIR/node.pem" -days 730
    
    # 设置证书权限
    chown -R opensearch:opensearch "$CERT_DIR"
    chmod 600 "$CERT_DIR"/*
    log "Certificates generated successfully"
else
    log "Using existing certificates"
fi

# 如果安全配置不存在，则初始化
if [ ! -d "$SECURITY_CONFIG_DIR" ]; then
    log "Initializing security configuration..."
    mkdir -p "$SECURITY_CONFIG_DIR"
    cp -r /usr/local/opensearch/plugins/opensearch-security/securityconfig/* "$SECURITY_CONFIG_DIR/"
    chown -R opensearch:opensearch "$SECURITY_CONFIG_DIR"
    chmod 600 "$SECURITY_CONFIG_DIR"/*
fi

# 确保配置文件包含必要的安全设置
if ! grep -q "plugins.security.ssl.transport.enabled" "$CONFIG_DIR/opensearch.yml"; then
    log "Adding security configuration to opensearch.yml..."
    cat >> "$CONFIG_DIR/opensearch.yml" <<EOF

# 安全配置
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
EOF
fi

# 重启 OpenSearch 使配置生效
log "Restarting OpenSearch to apply configuration..."
systemctl restart opensearch

# 等待服务启动
log "Waiting for OpenSearch to start..."
for i in {1..60}; do
    if systemctl is-active --quiet opensearch; then
        log "OpenSearch service is running"
        sleep 10  # 给予额外时间让配置生效
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# 创建新用户
log "Creating user $USERNAME..."
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
    warn "Please check the user credentials manually"
fi

log "OpenSearch user configuration completed!"
log "To connect to OpenSearch, use the following credentials:"
log "Username: $USERNAME"
log "Password: $PASSWORD"
log "Example curl command:"
log "curl -X GET \"https://localhost:9200/_cat/nodes?v\" -k -u \"$USERNAME:$PASSWORD\""

warn "Please make sure to update your Magento configuration with these credentials." 