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

# 显示帮助信息
show_help() {
    echo "Fail2ban 管理脚本"
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  install    - 安装 Fail2ban"
    echo "  status     - 检查 Fail2ban 状态"
    echo "  unban      - 解封指定IP"
    echo "  uninstall  - 卸载 Fail2ban"
}

# 安装 Fail2ban
install_fail2ban() {
    log "开始安装 Fail2ban..."
    
    # 安装软件包
    apt-get update
    apt-get install -y fail2ban || error "Fail2ban 安装失败"
    
    # 创建配置文件
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
# 封禁时间（秒）
bantime = 3600
# 查找时间范围（秒）
findtime = 600
# 允许失败次数
maxretry = 5
# 忽略的IP地址（比如你的办公室IP）
ignoreip = 127.0.0.1/8

# SSH 保护
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3

# Nginx 基本认证保护
[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

# Nginx 登录保护
[nginx-login]
enabled = true
filter = nginx-login
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5

# Nginx 限制请求
[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

# Magento 管理员登录保护
[magento-admin]
enabled = true
filter = magento-admin
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
EOF

    # 创建 Magento 管理员登录过滤器
    cat > /etc/fail2ban/filter.d/magento-admin.conf <<EOF
[Definition]
failregex = ^<HOST> .* "POST /admin/.*" (401|403|404)
ignoreregex =
EOF

    # 重启 Fail2ban
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    log "Fail2ban 安装完成"
    log "已配置保护："
    log "- SSH 登录保护"
    log "- Nginx 基本认证保护"
    log "- Nginx 登录保护"
    log "- Nginx 请求限制保护"
    log "- Magento 管理员登录保护"
    warn "请根据需要修改 /etc/fail2ban/jail.local 中的配置"
}

# 检查状态
check_status() {
    if ! command -v fail2ban-client &> /dev/null; then
        error "Fail2ban 未安装"
    fi
    
    log "Fail2ban 状态:"
    fail2ban-client status
    
    log "\n当前封禁的IP列表:"
    fail2ban-client banned
}

# 解封IP
unban_ip() {
    if [ -z "$1" ]; then
        error "请提供要解封的IP地址"
    fi
    
    if ! command -v fail2ban-client &> /dev/null; then
        error "Fail2ban 未安装"
    fi
    
    fail2ban-client set all unbanip "$1"
    log "已解封IP: $1"
}

# 卸载
uninstall_fail2ban() {
    log "开始卸载 Fail2ban..."
    
    # 停止服务
    systemctl stop fail2ban
    
    # 卸载软件包
    apt-get remove -y fail2ban
    apt-get autoremove -y
    
    # 清理配置文件
    rm -rf /etc/fail2ban
    
    log "Fail2ban 已卸载"
}

# 主逻辑
case "$1" in
    "install")
        install_fail2ban
        ;;
    "status")
        check_status
        ;;
    "unban")
        unban_ip "$2"
        ;;
    "uninstall")
        uninstall_fail2ban
        ;;
    *)
        show_help
        ;;
esac 