#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# 检查PHP配置
check_php_security() {
    log "Checking PHP security settings..."
    
    PHP_INI="/etc/php/8.2/fpm/php.ini"
    if [ ! -f "$PHP_INI" ]; then
        error "PHP configuration file not found"
    }

    # 检查关键安全设置
    EXPOSE_PHP=$(grep "^expose_php" "$PHP_INI" | cut -d= -f2 | tr -d ' ')
    if [ "$EXPOSE_PHP" != "Off" ]; then
        warn "PHP version is exposed in headers (expose_php = On)"
    }

    DISPLAY_ERRORS=$(grep "^display_errors" "$PHP_INI" | cut -d= -f2 | tr -d ' ')
    if [ "$DISPLAY_ERRORS" != "Off" ]; then
        warn "PHP errors are displayed to users (display_errors = On)"
    }
}

# 检查Nginx配置
check_nginx_security() {
    log "Checking Nginx security settings..."
    
    # 检查SSL配置
    if ! grep -r "ssl_protocols" /etc/nginx/sites-enabled/ > /dev/null; then
        warn "SSL protocols not explicitly defined in Nginx configuration"
    }

    # 检查服务器标识
    if ! grep -r "server_tokens off" /etc/nginx/nginx.conf > /dev/null; then
        warn "Nginx version is exposed in headers (server_tokens is not off)"
    }
}

# 检查MySQL配置
check_mysql_security() {
    log "Checking MySQL security settings..."
    
    # 检查远程root登录
    REMOTE_ROOT=$(mysql -N -e "SELECT host FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1')")
    if [ ! -z "$REMOTE_ROOT" ]; then
        warn "MySQL root user can connect from remote hosts"
    }

    # 检查匿名用户
    ANON_USERS=$(mysql -N -e "SELECT host FROM mysql.user WHERE user=''")
    if [ ! -z "$ANON_USERS" ]; then
        warn "Anonymous MySQL users exist"
    }
}

# 检查文件权限
check_file_permissions() {
    log "Checking file permissions..."
    
    # 检查关键目录权限
    find /var/www -type f -exec stat -c "%a %n" {} \; | while read perms file; do
        if [ "$perms" -gt "644" ]; then
            warn "Excessive permissions ($perms) on file: $file"
        fi
    done

    find /var/www -type d -exec stat -c "%a %n" {} \; | while read perms dir; do
        if [ "$perms" -gt "755" ]; then
            warn "Excessive permissions ($perms) on directory: $dir"
        fi
    done
}

# 检查系统安全
check_system_security() {
    log "Checking system security..."
    
    # 检查SSH配置
    if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
        warn "SSH root login is enabled"
    }

    # 检查防火墙状态
    if ! systemctl is-active --quiet ufw; then
        warn "UFW firewall is not active"
    }

    # 检查未使用的开放端口
    OPEN_PORTS=$(netstat -tuln | grep LISTEN)
    log "Open ports:"
    echo "$OPEN_PORTS"
}

# 运行所有检查
log "Starting security checks..."
check_php_security
check_nginx_security
check_mysql_security
check_file_permissions
check_system_security

log "Security check completed!"
log "Please review any warnings above and take appropriate action." 