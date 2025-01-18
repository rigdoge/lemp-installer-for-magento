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
    echo "ModSecurity 管理脚本"
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  install    - 安装 ModSecurity"
    echo "  enable     - 启用 ModSecurity"
    echo "  disable    - 禁用 ModSecurity"
    echo "  status     - 检查 ModSecurity 状态"
    echo "  uninstall  - 卸载 ModSecurity"
}

# 安装 ModSecurity
install_modsecurity() {
    log "开始安装 ModSecurity..."
    
    # 安装依赖
    apt-get update
    apt-get install -y \
        nginx-module-modsecurity \
        libmodsecurity3 \
        modsecurity-crs || error "ModSecurity 安装失败"
    
    # 创建配置目录
    mkdir -p /etc/nginx/modsec
    
    # 复制并准备配置文件
    cp /etc/modsecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
    
    # 修改基本配置
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
    
    # 创建主配置文件
    cat > /etc/nginx/modsec/main.conf <<EOF
Include "/etc/nginx/modsec/modsecurity.conf"
Include "/usr/share/modsecurity-crs/rules/*.conf"

# 基本规则
SecRule REQUEST_HEADERS:Content-Type "text/xml" \
     "id:1999,\
     phase:1,\
     pass,\
     nolog,\
     setvar:tx.xml_data=1"

# 放行Magento后台路径
SecRule REQUEST_URI "@beginsWith /admin" \
     "id:2000,\
     phase:1,\
     pass,\
     nolog,\
     ctl:ruleEngine=Off"
EOF
    
    # 配置Nginx加载ModSecurity
    cat > /etc/nginx/conf.d/modsecurity.conf <<EOF
load_module modules/ngx_http_modsecurity_module.so;

modsecurity on;
modsecurity_rules_file /etc/nginx/modsec/main.conf;
EOF
    
    # 创建开关控制文件
    echo "enabled" > /etc/nginx/modsec/status
    
    log "ModSecurity 安装完成"
    log "默认使用OWASP核心规则集，并已配置基本的Magento例外规则"
    warn "请注意检查Nginx错误日志以监控误报情况"
}

# 启用 ModSecurity
enable_modsecurity() {
    if [ ! -f /etc/nginx/modsec/status ]; then
        error "ModSecurity 未安装，请先运行 install 命令"
    fi
    
    sed -i 's/modsecurity off/modsecurity on/' /etc/nginx/conf.d/modsecurity.conf
    echo "enabled" > /etc/nginx/modsec/status
    systemctl restart nginx
    
    log "ModSecurity 已启用"
}

# 禁用 ModSecurity
disable_modsecurity() {
    if [ ! -f /etc/nginx/modsec/status ]; then
        error "ModSecurity 未安装，请先运行 install 命令"
    fi
    
    sed -i 's/modsecurity on/modsecurity off/' /etc/nginx/conf.d/modsecurity.conf
    echo "disabled" > /etc/nginx/modsec/status
    systemctl restart nginx
    
    log "ModSecurity 已禁用"
}

# 检查 ModSecurity 状态
check_status() {
    if [ ! -f /etc/nginx/modsec/status ]; then
        log "ModSecurity 未安装"
        return
    fi
    
    STATUS=$(cat /etc/nginx/modsec/status)
    if [ "$STATUS" == "enabled" ]; then
        log "ModSecurity 状态: 已启用"
    else
        log "ModSecurity 状态: 已禁用"
    fi
    
    # 检查规则命中情况
    if [ -f /var/log/nginx/error.log ]; then
        RULES_TRIGGERED=$(grep "ModSecurity: Rule" /var/log/nginx/error.log | wc -l)
        log "最近规则命中次数: $RULES_TRIGGERED"
    fi
}

# 卸载 ModSecurity
uninstall_modsecurity() {
    log "开始卸载 ModSecurity..."
    
    # 移除Nginx配置
    rm -f /etc/nginx/conf.d/modsecurity.conf
    
    # 卸载软件包
    apt-get remove -y nginx-module-modsecurity libmodsecurity3 modsecurity-crs
    apt-get autoremove -y
    
    # 清理配置文件
    rm -rf /etc/nginx/modsec
    
    log "ModSecurity 已卸载"
}

# 主逻辑
case "$1" in
    "install")
        install_modsecurity
        ;;
    "enable")
        enable_modsecurity
        ;;
    "disable")
        disable_modsecurity
        ;;
    "status")
        check_status
        ;;
    "uninstall")
        uninstall_modsecurity
        ;;
    *)
        show_help
        ;;
esac 