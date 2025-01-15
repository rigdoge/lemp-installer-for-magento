#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查参数
if [ "$#" -ne 4 ]; then
    error "Usage: $0 <db_name> <db_user> <db_password> <root_password>"
fi

DB_NAME=$1
DB_USER=$2
DB_PASSWORD=$3
ROOT_PASSWORD=$4

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 设置MySQL root密码
log "Setting MySQL root password..."
mysql --connect-expired-password -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';" || error "Failed to set root password"

# 创建数据库
log "Creating database $DB_NAME..."
mysql -u root -p"$ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || error "Failed to create database"

# 创建用户并授权
log "Creating user $DB_USER and granting privileges..."
mysql -u root -p"$ROOT_PASSWORD" <<EOF || error "Failed to create user and grant privileges"
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# 优化MySQL配置
log "Optimizing MySQL configuration..."
cat > /etc/mysql/conf.d/magento.cnf <<EOF
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_log_buffer_size = 8M
innodb_file_per_table = 1
innodb_open_files = 400
innodb_io_capacity = 400
innodb_flush_method = O_DIRECT
max_allowed_packet = 128M
EOF

# 重启MySQL服务
log "Restarting MySQL service..."
systemctl restart mysql || error "Failed to restart MySQL"

log "MySQL configuration completed successfully!"
log "Database: $DB_NAME"
log "User: $DB_USER"
log "Please save your passwords in a secure location." 