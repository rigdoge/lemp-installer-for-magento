#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/smtp.conf"

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "错误：配置文件不存在 ($CONFIG_FILE)"
    exit 1
fi

# 发送邮件函数
send_mail() {
    local to="$1"
    local subject="$2"
    local body="$3"
    local attachment="$4"
    
    # 准备邮件内容
    local email_content=$(mktemp)
    
    # 添加邮件头
    cat > "$email_content" << EOF
From: $SMTP_FROM
To: $to
Subject: $subject
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="boundary"

--boundary
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: 8bit

$body

EOF
    
    # 如果有附件，添加附件
    if [ -n "$attachment" ] && [ -f "$attachment" ]; then
        local filename=$(basename "$attachment")
        local mimetype=$(file -b --mime-type "$attachment")
        
        cat >> "$email_content" << EOF
--boundary
Content-Type: $mimetype; name="$filename"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="$filename"

$(base64 "$attachment")
EOF
    fi
    
    # 结束邮件
    echo "--boundary--" >> "$email_content"
    
    # 根据加密方式选择发送命令
    local smtp_command
    case "$SMTP_ENCRYPTION" in
        "none")
            smtp_command="sendmail -t"
            ;;
        "ssl"|"tls")
            smtp_command="openssl s_client -quiet -${SMTP_ENCRYPTION} -connect ${SMTP_HOST}:${SMTP_PORT} -starttls smtp"
            ;;
        "starttls")
            smtp_command="openssl s_client -quiet -tls -connect ${SMTP_HOST}:${SMTP_PORT} -starttls smtp"
            ;;
        *)
            echo "错误：不支持的加密方式: $SMTP_ENCRYPTION"
            rm -f "$email_content"
            return 1
            ;;
    esac
    
    # 发送邮件
    if [ "$SMTP_ENCRYPTION" = "none" ]; then
        cat "$email_content" | $smtp_command
    else
        (
            sleep 1
            echo "EHLO $(hostname)"
            sleep 1
            echo "AUTH LOGIN"
            sleep 1
            echo "$(echo -n "$SMTP_USERNAME" | base64)"
            sleep 1
            echo "$(echo -n "$SMTP_PASSWORD" | base64)"
            sleep 1
            echo "MAIL FROM: <$SMTP_FROM>"
            sleep 1
            echo "RCPT TO: <$to>"
            sleep 1
            echo "DATA"
            sleep 1
            cat "$email_content"
            sleep 1
            echo "."
            sleep 1
            echo "QUIT"
        ) | $smtp_command
    fi
    
    # 清理临时文件
    rm -f "$email_content"
    
    return $?
}

# 主函数
main() {
    if [ $# -lt 3 ]; then
        echo "用法: $0 <收件人> <主题> <内容> [附件]"
        exit 1
    fi
    
    local to="$1"
    local subject="$2"
    local body="$3"
    local attachment="$4"
    
    send_mail "$to" "$subject" "$body" "$attachment"
    
    if [ $? -eq 0 ]; then
        echo "邮件发送成功"
    else
        echo "邮件发送失败"
        exit 1
    fi
}

# 运行主函数
main "$@" 