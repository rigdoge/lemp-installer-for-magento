#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 配置文件路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/telegram.conf"

# 加载配置
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置 Telegram Bot
configure_bot() {
    read -p "Enter your Telegram Bot Token: " BOT_TOKEN
    
    # 验证 Bot Token
    local response
    response=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getMe")
    if ! echo "$response" | grep -q '"ok":true'; then
        log_error "Invalid Bot Token"
        return 1
    fi
    
    # 获取 Chat ID
    log_info "Please send a message to your bot"
    log_info "Then run: curl https://api.telegram.org/bot$BOT_TOKEN/getUpdates"
    log_info "Look for 'chat':{'id': YOUR_CHAT_ID}"
    read -p "Enter the Chat ID: " CHAT_ID
    
    # 保存配置
    cat > "$CONFIG_FILE" << EOF
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
EOF
    
    chmod 600 "$CONFIG_FILE"
    
    # 发送测试消息
    send_message "Telegram Bot configured successfully!"
}

# 发送消息
send_message() {
    local message="$1"
    local parse_mode="${2:-HTML}"
    
    if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        log_error "Bot not configured. Please run configure_bot first"
        return 1
    fi
    
    local response
    response=$(curl -s -X POST \
        "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message" \
        -d "parse_mode=$parse_mode")
        
    if echo "$response" | grep -q '"ok":true'; then
        log_info "Message sent successfully"
        return 0
    else
        log_error "Failed to send message: $response"
        return 1
    fi
}

# 主函数
main() {
    case "$1" in
        configure)
            configure_bot
            ;;
        send)
            shift
            send_message "$*"
            ;;
        *)
            echo "Usage: $0 {configure|send message}"
            exit 1
            ;;
    esac
}

main "$@" 