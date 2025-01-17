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

# 检查 OpenSearch 是否已安装
if ! command -v opensearch >/dev/null 2>&1; then
    error "OpenSearch is not installed. Please install OpenSearch first."
fi

# 检查并安装必要的软件包
log "Checking and installing required packages..."
apt-get update
apt-get install -y openjdk-17-jdk openssl curl

# 设置目录
OPENSEARCH_HOME="/usr/local/opensearch"
CONFIG_DIR="$OPENSEARCH_HOME/config"
CERT_DIR="$CONFIG_DIR/certificates"
SECURITY_CONFIG_DIR="$CONFIG_DIR/opensearch-security"
PLUGINS_DIR="$OPENSEARCH_HOME/plugins"

# 创建必要的目录
log "Creating necessary directories..."
mkdir -p "$CERT_DIR"
mkdir -p "$SECURITY_CONFIG_DIR"

# 生成证书配置文件
log "Generating certificate configuration..."
cat > "$CERT_DIR/openssl.cnf" <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = v3_req
distinguished_name = dn

[ dn ]
C = CN
ST = Shanghai
L = Shanghai
O = Magento Multi-site
OU = Web Operations
CN = opensearch.local

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always

[ alt_names ]
DNS.1 = localhost
DNS.2 = opensearch.local
DNS.3 = *.magento.local
DNS.4 = *.local
IP.1 = 127.0.0.1
EOF

# 生成证书
log "Generating certificates..."
# 生成根证书
openssl genrsa -out "$CERT_DIR/root-ca-key.pem" 4096
openssl req -new -x509 -sha256 -key "$CERT_DIR/root-ca-key.pem" -out "$CERT_DIR/root-ca.pem" -days 730 \
    -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Magento Multi-site/OU=Web Operations/CN=Root CA"

# 生成节点证书
openssl genrsa -out "$CERT_DIR/node-key.pem" 2048
openssl req -new -key "$CERT_DIR/node-key.pem" -out "$CERT_DIR/node.csr" -config "$CERT_DIR/openssl.cnf"
openssl x509 -req -in "$CERT_DIR/node.csr" -CA "$CERT_DIR/root-ca.pem" -CAkey "$CERT_DIR/root-ca-key.pem" \
    -CAcreateserial -sha256 -out "$CERT_DIR/node.pem" -days 730 -extensions v3_req -extfile "$CERT_DIR/openssl.cnf"

# 生成客户端证书
openssl genrsa -out "$CERT_DIR/client-key.pem" 2048
openssl req -new -key "$CERT_DIR/client-key.pem" -out "$CERT_DIR/client.csr" \
    -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Magento Multi-site/OU=Client/CN=client.magento.local"
openssl x509 -req -in "$CERT_DIR/client.csr" -CA "$CERT_DIR/root-ca.pem" -CAkey "$CERT_DIR/root-ca-key.pem" \
    -CAcreateserial -sha256 -out "$CERT_DIR/client.pem" -days 730

# 设置证书权限
chown -R opensearch:opensearch "$CERT_DIR"
chmod 600 "$CERT_DIR"/*.pem
chmod 644 "$CERT_DIR/root-ca.pem"

# 配置 OpenSearch
log "Configuring OpenSearch..."
cat > "$CONFIG_DIR/opensearch.yml" <<EOF
# 集群设置
cluster.name: magento-cluster
node.name: node-1
node.roles: [ data, master, ingest ]

# 网络设置
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300

# 发现设置
discovery.type: single-node

# 内存设置
bootstrap.memory_lock: true

# 路径设置
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch

# 安全设置
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
  - "CN=client.magento.local,OU=Client,O=Magento Multi-site,L=Shanghai,ST=Shanghai,C=CN"
plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]

# 性能优化
thread_pool.write.queue_size: 1000
thread_pool.search.queue_size: 1000
indices.queries.cache.size: 25%
indices.memory.index_buffer_size: 30%

# 索引设置
action.auto_create_index: +*,-security-auditlog-*,-.*
action.destructive_requires_name: true

# 日志设置
logger.level: WARN
EOF

# 复制默认安全配置
log "Setting up security configuration..."
if [ -d "$PLUGINS_DIR/opensearch-security/securityconfig" ]; then
    cp -r "$PLUGINS_DIR/opensearch-security/securityconfig/"* "$SECURITY_CONFIG_DIR/"
else
    error "Security configuration template not found. Please check OpenSearch installation."
fi

# 设置配置文件权限
chown -R opensearch:opensearch "$CONFIG_DIR"
chmod -R 600 "$CONFIG_DIR"
chmod 750 "$CONFIG_DIR" "$SECURITY_CONFIG_DIR" "$CERT_DIR"

# 重启 OpenSearch
log "Restarting OpenSearch..."
systemctl restart opensearch

# 等待服务启动
log "Waiting for OpenSearch to start..."
max_attempts=60
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -sk "https://localhost:9200/_cluster/health" >/dev/null 2>&1; then
        log "OpenSearch is ready!"
        break
    fi
    echo -n "."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    error "OpenSearch failed to start. Please check logs at /var/log/opensearch/magento-cluster.log"
fi

# 初始化安全配置
log "Initializing security configuration..."
"$PLUGINS_DIR/opensearch-security/tools/securityadmin.sh" \
    -cd "$SECURITY_CONFIG_DIR" \
    -icl -nhnv \
    -cacert "$CERT_DIR/root-ca.pem" \
    -cert "$CERT_DIR/node.pem" \
    -key "$CERT_DIR/node-key.pem"

# 创建用户
log "Creating user $USERNAME..."
curl -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/$USERNAME" \
    -H 'Content-Type: application/json' \
    -k -u "admin:admin" \
    -d "{
  \"password\": \"$PASSWORD\",
  \"backend_roles\": [\"admin\", \"all_access\"],
  \"attributes\": {
    \"type\": \"magento_admin\",
    \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
  },
  \"description\": \"Magento OpenSearch administrator\"
}"

# 验证配置
log "Verifying configuration..."
HEALTH_RESPONSE=$(curl -sk -u "$USERNAME:$PASSWORD" "https://localhost:9200/_cluster/health")
if [ $? -eq 0 ] && echo "$HEALTH_RESPONSE" | grep -q '"status"'; then
    log "Configuration successful!"
    log "Cluster health: $HEALTH_RESPONSE"
else
    warn "Configuration verification failed"
    warn "Response: $HEALTH_RESPONSE"
    warn "Please check the configuration manually"
fi

# 输出配置信息
log "OpenSearch configuration completed!"
log "Important information:"
log "1. Root CA certificate: $CERT_DIR/root-ca.pem"
log "2. Node certificate: $CERT_DIR/node.pem"
log "3. Client certificate: $CERT_DIR/client.pem"
log "4. Username: $USERNAME"
log "5. Password: $PASSWORD"
log ""
log "To test the connection:"
log "curl -k -X GET \"https://localhost:9200/_cat/nodes?v\" -u \"$USERNAME:$PASSWORD\""
log ""
warn "Please make sure to:"
warn "1. Update your Magento configuration with these credentials"
warn "2. Import the root CA certificate into your trusted certificates if needed"
warn "3. Backup the certificates in $CERT_DIR"
warn "4. Consider changing the default admin password after initial setup" 