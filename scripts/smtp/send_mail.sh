#!/bin/bash

send_mail() {
    local to="$1"
    local subject="$2"
    local body="$3"
    local attachment="$4"

    # 添加详细日志
    log_info "Attempting to send email to: $to"
    log_info "Using SMTP server: $SMTP_HOST:$SMTP_PORT"
    log_info "From address: $SMTP_FROM"
    
    # 测试SMTP连接
    if ! nc -zv $SMTP_HOST $SMTP_PORT 2>/dev/null; then
        log_error "Cannot connect to SMTP server"
        return 1
    }
    
    local mail_cmd="swaks --to $to --from $SMTP_FROM --server $SMTP_HOST:$SMTP_PORT"
    mail_cmd+=" --auth-user $SMTP_USERNAME --auth-password $SMTP_PASSWORD"
    mail_cmd+=" --tls --header 'Subject: $subject' --body '$body'"
    
    if [ -n "$attachment" ]; then
        mail_cmd+=" --attach-type application/octet-stream --attach $attachment"
    fi
    
    # 执行发送并记录结果
    local result
    result=$(eval $mail_cmd 2>&1)
    local status=$?
    
    if [ $status -eq 0 ]; then
        log_info "Email sent successfully. SMTP response: $result"
    else
        log_error "Failed to send email. Error: $result"
    fi
    
    return $status
} 