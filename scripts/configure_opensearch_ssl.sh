#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 检查 OpenSearch 是否安装
if ! systemctl is-active --quiet opensearch; then
    error "OpenSearch is not running. Please install and start OpenSearch first."
fi

# 创建证书目录
CERT_DIR="/usr/local/opensearch/config/certificates"
mkdir -p "$CERT_DIR"

# 生成根证书
log "Generating root CA..."
openssl genrsa -out "$CERT_DIR/root-ca-key.pem" 2048
openssl req -new -x509 -sha256 -key "$CERT_DIR/root-ca-key.pem" -out "$CERT_DIR/root-ca.pem" -days 730 -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Magento/OU=OpenSearch/CN=Root CA"

# 生成管理员证书
log "Generating admin certificate..."
openssl genrsa -out "$CERT_DIR/admin-key-temp.pem" 2048
openssl pkcs8 -inform PEM -outform PEM -in "$CERT_DIR/admin-key-temp.pem" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "$CERT_DIR/admin-key.pem"
openssl req -new -key "$CERT_DIR/admin-key.pem" -out "$CERT_DIR/admin.csr" -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Magento/OU=OpenSearch/CN=admin"
openssl x509 -req -in "$CERT_DIR/admin.csr" -CA "$CERT_DIR/root-ca.pem" -CAkey "$CERT_DIR/root-ca-key.pem" -CAcreateserial -out "$CERT_DIR/admin.pem" -days 730 -sha256

# 生成节点证书
log "Generating node certificate..."
openssl genrsa -out "$CERT_DIR/node-key-temp.pem" 2048
openssl pkcs8 -inform PEM -outform PEM -in "$CERT_DIR/node-key-temp.pem" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "$CERT_DIR/node-key.pem"
openssl req -new -key "$CERT_DIR/node-key.pem" -out "$CERT_DIR/node.csr" -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Magento/OU=OpenSearch/CN=node"
openssl x509 -req -in "$CERT_DIR/node.csr" -CA "$CERT_DIR/root-ca.pem" -CAkey "$CERT_DIR/root-ca-key.pem" -CAcreateserial -out "$CERT_DIR/node.pem" -days 730 -sha256

# 清理临时文件
rm -f "$CERT_DIR/admin-key-temp.pem" "$CERT_DIR/node-key-temp.pem" "$CERT_DIR/admin.csr" "$CERT_DIR/node.csr"

# 设置权限
chown -R opensearch:opensearch "$CERT_DIR"
chmod -R 600 "$CERT_DIR"
chmod 700 "$CERT_DIR"

# 更新 OpenSearch 配置
log "Updating OpenSearch configuration..."
cat >> /usr/local/opensearch/config/opensearch.yml <<EOF

# SSL/TLS Configuration
plugins.security.ssl.transport.pemcert_filepath: certificates/node.pem
plugins.security.ssl.transport.pemkey_filepath: certificates/node-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: certificates/root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: certificates/node.pem
plugins.security.ssl.http.pemkey_filepath: certificates/node-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: certificates/root-ca.pem
plugins.security.allow_unsafe_democertificates: false
plugins.security.allow_default_init_securityindex: true
plugins.security.authcz.admin_dn:
  - "CN=admin,OU=OpenSearch,O=Magento,L=Shanghai,ST=Shanghai,C=CN"
plugins.security.nodes_dn:
  - "CN=node,OU=OpenSearch,O=Magento,L=Shanghai,ST=Shanghai,C=CN"
plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
EOF

# 重启 OpenSearch
log "Restarting OpenSearch..."
systemctl restart opensearch

# 等待服务启动
log "Waiting for OpenSearch to start..."
sleep 30

# 测试 HTTPS 连接
log "Testing HTTPS connection..."
curl -k -X GET "https://localhost:9200/_cat/nodes?v" \
  --cert "$CERT_DIR/admin.pem" \
  --key "$CERT_DIR/admin-key.pem" \
  --cacert "$CERT_DIR/root-ca.pem"

log "OpenSearch SSL configuration completed!"
log "To connect to OpenSearch, use the following certificates:"
log "Admin cert: $CERT_DIR/admin.pem"
log "Admin key: $CERT_DIR/admin-key.pem"
log "Root CA: $CERT_DIR/root-ca.pem"
log "Example curl command:"
log 'curl -k -X GET "https://localhost:9200/_cat/nodes?v" --cert admin.pem --key admin-key.pem --cacert root-ca.pem' 