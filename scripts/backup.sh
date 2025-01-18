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
    error "Usage: $0 <magento_root> <db_name> <db_user> <db_password>"
fi

MAGENTO_ROOT=$1
DB_NAME=$2
DB_USER=$3
DB_PASSWORD=$4

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 创建备份目录
BACKUP_DIR="../backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份数据库
log "Backing up database $DB_NAME..."
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/$DB_NAME.sql" || error "Failed to backup database"

# 备份网站文件
log "Backing up Magento files..."
tar -czf "$BACKUP_DIR/magento_files.tar.gz" -C "$(dirname "$MAGENTO_ROOT")" "$(basename "$MAGENTO_ROOT")" || error "Failed to backup files"

# 备份Nginx配置
log "Backing up Nginx configuration..."
cp -r /etc/nginx/sites-available "$BACKUP_DIR/nginx_sites_available" || error "Failed to backup Nginx configuration"

# 备份PHP配置
log "Backing up PHP configuration..."
cp /etc/php/8.2/fpm/php.ini "$BACKUP_DIR/php.ini" || error "Failed to backup PHP configuration"

# 设置权限
chmod 600 "$BACKUP_DIR/$DB_NAME.sql"
chmod 600 "$BACKUP_DIR/magento_files.tar.gz"

log "Backup completed successfully!"
log "Backup location: $BACKUP_DIR"
log "Files backed up:"
log "- Database dump: $BACKUP_DIR/$DB_NAME.sql"
log "- Magento files: $BACKUP_DIR/magento_files.tar.gz"
log "- Nginx configuration: $BACKUP_DIR/nginx_sites_available"
log "- PHP configuration: $BACKUP_DIR/php.ini" 