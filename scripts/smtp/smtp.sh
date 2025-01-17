#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/smtp.conf"

# 初始化日志
init_log() {
    # 创建日志目录
    local log_dir=$(dirname "$LOG_FILE")
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
        chmod 755 "$log_dir"
    fi
    
    # 创建日志文件（如果不存在）
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
    fi
}

# 检查配置文件权限
check_config_permissions() {
    local config_dir=$(dirname "$CONFIG_FILE")
    
    # 检查配置目录权限
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
        chmod 750 "$config_dir"
    fi
    
    # 检查配置文件权限
    if [ -f "$CONFIG_FILE" ]; then
        current_perm=$(stat -f "%Lp" "$CONFIG_FILE")
        if [ "$current_perm" != "600" ]; then
            chmod 600 "$CONFIG_FILE"
            log "WARN" "配置文件权限已更正为 600"
        fi
    fi
}

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    check_config_permissions
    source "$CONFIG_FILE"
    init_log
else
    echo -e "${RED}错误：配置文件不存在 ($CONFIG_FILE)${NC}"
    exit 1
fi

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "$timestamp [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR")
            echo -e "${RED}错误：$message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}警告：$message${NC}"
            ;;
        "INFO")
            echo -e "${GREEN}信息：$message${NC}"
            ;;
        *)
            echo -e "$message"
            ;;
    esac
}

# 加密函数
encrypt_password() {
    local password="$1"
    echo "$password" | openssl enc -aes-256-cbc -a -salt -pass pass:"smtp_secret_key"
}

# 解密函数
decrypt_password() {
    local encrypted_password="$1"
    echo "$encrypted_password" | openssl enc -aes-256-cbc -a -d -salt -pass pass:"smtp_secret_key"
}

# 配置提供商
configure_provider() {
    local provider="$1"
    shift
    
    case "$provider" in
        "microsoft365")
            SMTP_PROVIDER="microsoft365"
            SMTP_HOST="$MICROSOFT365_HOST"
            SMTP_PORT="$MICROSOFT365_PORT"
            SMTP_ENCRYPTION="$MICROSOFT365_ENCRYPTION"
            ;;
        "gmail")
            SMTP_PROVIDER="gmail"
            SMTP_HOST="$GMAIL_HOST"
            SMTP_PORT="$GMAIL_PORT"
            SMTP_ENCRYPTION="$GMAIL_ENCRYPTION"
            ;;
        "sendgrid")
            SMTP_PROVIDER="sendgrid"
            SMTP_HOST="$SENDGRID_HOST"
            SMTP_PORT="$SENDGRID_PORT"
            SMTP_ENCRYPTION="$SENDGRID_ENCRYPTION"
            ;;
        "ses")
            SMTP_PROVIDER="ses"
            read -p "请输入 AWS 区域: " AWS_REGION
            SMTP_HOST="${SES_HOST/\{region\}/$AWS_REGION}"
            SMTP_PORT="$SES_PORT"
            SMTP_ENCRYPTION="$SES_ENCRYPTION"
            read -p "请输入 AWS Access Key: " AWS_ACCESS_KEY
            read -s -p "请输入 AWS Secret Key: " AWS_SECRET_KEY
            echo
            ;;
        "mailgun")
            SMTP_PROVIDER="mailgun"
            SMTP_HOST="$MAILGUN_HOST"
            SMTP_PORT="$MAILGUN_PORT"
            SMTP_ENCRYPTION="$MAILGUN_ENCRYPTION"
            read -p "请输入 Mailgun 域名: " MAILGUN_DOMAIN
            read -s -p "请输入 Mailgun API Key: " MAILGUN_API_KEY
            echo
            ;;
        "custom")
            SMTP_PROVIDER="custom"
            read -p "请输入 SMTP 服务器地址: " SMTP_HOST
            read -p "请输入 SMTP 端口: " SMTP_PORT
            read -p "请输入加密方式 (none|ssl|tls|starttls): " SMTP_ENCRYPTION
            ;;
        *)
            log "ERROR" "不支持的提供商: $provider"
            exit 1
            ;;
    esac
    
    # 通用配置
    read -p "请输入 SMTP 用户名: " SMTP_USERNAME
    read -s -p "请输入 SMTP 密码: " SMTP_PASSWORD
    echo
    read -p "请输入发件人地址: " SMTP_FROM
    
    # 加密密码
    SMTP_PASSWORD=$(encrypt_password "$SMTP_PASSWORD")
    
    # 保存配置
    save_config
    
    log "INFO" "SMTP 配置已完成"
}

# 保存配置
save_config() {
    # 创建临时配置文件
    local temp_config=$(mktemp)
    
    # 写入配置
    cat > "$temp_config" << EOF
# SMTP 基础配置
SMTP_PROVIDER="$SMTP_PROVIDER"
SMTP_HOST="$SMTP_HOST"
SMTP_PORT="$SMTP_PORT"
SMTP_USERNAME="$SMTP_USERNAME"
SMTP_PASSWORD="$SMTP_PASSWORD"
SMTP_FROM="$SMTP_FROM"
SMTP_ENCRYPTION="$SMTP_ENCRYPTION"

# Microsoft 365 配置
MICROSOFT365_HOST="$MICROSOFT365_HOST"
MICROSOFT365_PORT="$MICROSOFT365_PORT"
MICROSOFT365_ENCRYPTION="$MICROSOFT365_ENCRYPTION"

# Gmail 配置
GMAIL_HOST="$GMAIL_HOST"
GMAIL_PORT="$GMAIL_PORT"
GMAIL_ENCRYPTION="$GMAIL_ENCRYPTION"

# SendGrid 配置
SENDGRID_HOST="$SENDGRID_HOST"
SENDGRID_PORT="$SENDGRID_PORT"
SENDGRID_ENCRYPTION="$SENDGRID_ENCRYPTION"

# Amazon SES 配置
SES_HOST="$SES_HOST"
SES_PORT="$SES_PORT"
SES_ENCRYPTION="$SES_ENCRYPTION"
AWS_REGION="$AWS_REGION"
AWS_ACCESS_KEY="$AWS_ACCESS_KEY"
AWS_SECRET_KEY="$AWS_SECRET_KEY"

# Mailgun 配置
MAILGUN_HOST="$MAILGUN_HOST"
MAILGUN_PORT="$MAILGUN_PORT"
MAILGUN_ENCRYPTION="$MAILGUN_ENCRYPTION"
MAILGUN_DOMAIN="$MAILGUN_DOMAIN"
MAILGUN_API_KEY="$MAILGUN_API_KEY"

# 日志配置
LOG_FILE="$LOG_FILE"
LOG_LEVEL="$LOG_LEVEL"

# 重试配置
MAX_RETRY=$MAX_RETRY
RETRY_INTERVAL=$RETRY_INTERVAL
EOF
    
    # 替换配置文件
    mv "$temp_config" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    log "INFO" "配置已保存到 $CONFIG_FILE"
}

# 测试连接
test_connection() {
    local host="$SMTP_HOST"
    local port="$SMTP_PORT"
    
    log "INFO" "测试连接 $host:$port..."
    
    if nc -zv "$host" "$port" 2>/dev/null; then
        log "INFO" "连接成功"
        return 0
    else
        log "ERROR" "连接失败"
        return 1
    fi
}

# 测试发送
test_send() {
    local to="$1"
    local subject="SMTP 测试邮件"
    local body="这是一封测试邮件，用于验证 SMTP 配置。\n\n发送时间: $(date '+%Y-%m-%d %H:%M:%S')\n配置信息:\n- 提供商: $SMTP_PROVIDER\n- 服务器: $SMTP_HOST:$SMTP_PORT\n- 加密方式: $SMTP_ENCRYPTION"
    
    log "INFO" "发送测试邮件到 $to..."
    
    # 调用发送脚本
    if "$SCRIPT_DIR/smtp_send.sh" "$to" "$subject" "$body"; then
        log "INFO" "测试邮件发送成功"
        return 0
    else
        log "ERROR" "测试邮件发送失败"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "用法: $0 <命令> [选项]"
    echo
    echo "命令:"
    echo "  config <provider>  配置 SMTP 提供商"
    echo "  test connection    测试 SMTP 连接"
    echo "  test send <to>     发送测试邮件"
    echo "  status            显示当前配置状态"
    echo "  help              显示此帮助信息"
    echo
    echo "提供商:"
    echo "  microsoft365      Microsoft 365"
    echo "  gmail            Gmail"
    echo "  sendgrid         SendGrid"
    echo "  ses              Amazon SES"
    echo "  mailgun          Mailgun"
    echo "  custom           自定义 SMTP"
    echo
    echo "选项:"
    echo "  --encryption <type>  设置加密类型 (none|ssl|tls|starttls)"
    echo "  --port <number>      设置端口号"
}

# 显示状态
show_status() {
    echo "SMTP 配置状态:"
    echo "提供商: $SMTP_PROVIDER"
    echo "服务器: $SMTP_HOST"
    echo "端口: $SMTP_PORT"
    echo "加密: $SMTP_ENCRYPTION"
    echo "用户名: $SMTP_USERNAME"
    echo "发件人: $SMTP_FROM"
}

# 主函数
main() {
    case "$1" in
        "config")
            if [ -z "$2" ]; then
                log "ERROR" "请指定提供商"
                show_help
                exit 1
            fi
            configure_provider "$2"
            ;;
        "test")
            case "$2" in
                "connection")
                    test_connection
                    ;;
                "send")
                    if [ -z "$3" ]; then
                        log "ERROR" "请指定收件人地址"
                        exit 1
                    fi
                    test_send "$3"
                    ;;
                *)
                    log "ERROR" "未知的测试类型: $2"
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        "status")
            show_status
            ;;
        "help")
            show_help
            ;;
        *)
            log "ERROR" "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@" 