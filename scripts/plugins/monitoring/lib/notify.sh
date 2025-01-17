#!/bin/bash

# 加载配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../available/monitor.conf" ]; then
    source "$SCRIPT_DIR/../available/monitor.conf"
fi

# 通知历史记录
HISTORY_FILE="/var/log/monitoring/notification_history.log"

# 检查是否需要发送通知
should_send_notification() {
    local service="$1"
    local status="$2"
    local last_notification
    
    # 检查历史记录
    if [ -f "$HISTORY_FILE" ]; then
        last_notification=$(grep "^$service:$status:" "$HISTORY_FILE" | tail -n 1 | cut -d: -f3)
        if [ -n "$last_notification" ]; then
            current_time=$(date +%s)
            time_diff=$((current_time - last_notification))
            if [ $time_diff -lt $NOTIFICATION_INTERVAL ]; then
                return 1
            fi
        fi
    fi
    return 0
}

# 记录通知历史
record_notification() {
    local service="$1"
    local status="$2"
    local timestamp=$(date +%s)
    
    mkdir -p "$(dirname "$HISTORY_FILE")"
    echo "$service:$status:$timestamp" >> "$HISTORY_FILE"
}

# 发送通知
send_notification() {
    local level="$1"    # error, warning, recovery
    local service="$2"
    local status="$3"
    local details="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 检查是否需要发送通知
    if ! should_send_notification "$service" "$status"; then
        return 0
    fi
    
    # 根据级别选择模板
    local template
    case "$level" in
        error)
            [ "$NOTIFY_ON_ERROR" = "true" ] || return 0
            template="$ERROR_TEMPLATE"
            ;;
        warning)
            [ "$NOTIFY_ON_WARNING" = "true" ] || return 0
            template="$WARNING_TEMPLATE"
            ;;
        recovery)
            [ "$NOTIFY_ON_RECOVERY" = "true" ] || return 0
            template="$RECOVERY_TEMPLATE"
            ;;
        *)
            echo "Unknown notification level: $level"
            return 1
            ;;
    esac
    
    # 格式化消息
    local message
    if [ "$level" = "recovery" ]; then
        message=$(printf "$template" "$service" "$details" "$timestamp")
    else
        message=$(printf "$template" "$service" "$status" "$details" "$timestamp")
    fi
    
    # 发送通知
    case "$NOTIFICATION_TYPE" in
        telegram|both)
            $TELEGRAM_SCRIPT send "$message"
            ;;
        email|both)
            # TODO: 添加邮件发送支持
            ;;
    esac
    
    # 记录通知历史
    record_notification "$service" "$status"
} 