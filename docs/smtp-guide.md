# SMTP 配置指南

## 功能概述

SMTP 模块提供了灵活的邮件发送配置，支持多个主流 SMTP 服务提供商，包括：
- Microsoft 365
- Gmail
- SendGrid
- Amazon SES
- Mailgun
- 自定义 SMTP 服务器

## 支持的功能
- 多服务商配置
- 多种加密方式（none/SSL/TLS/STARTTLS）
- 附件支持
- 日志记录
- 重试机制
- 连接测试
- 发送测试

## 配置说明

### 1. 基础配置
配置文件位置：`scripts/smtp/smtp.conf`

主要配置项：
```bash
# SMTP 基础配置
SMTP_PROVIDER=""        # 服务提供商
SMTP_HOST=""           # SMTP 服务器地址
SMTP_PORT=""           # SMTP 端口
SMTP_USERNAME=""       # SMTP 用户名
SMTP_PASSWORD=""       # SMTP 密码
SMTP_FROM=""          # 发件人地址
SMTP_ENCRYPTION="none" # 加密方式 (none|ssl|tls|starttls)
```

### 2. 服务商配置

#### Microsoft 365
```bash
Host: smtp.office365.com
Port: 587
Encryption: none（推荐）或 tls
```

#### Gmail
```bash
Host: smtp.gmail.com
Port: 587
Encryption: tls
注意：需要启用"应用专用密码"
```

#### SendGrid
```bash
Host: smtp.sendgrid.net
Port: 587
Encryption: tls
```

#### Amazon SES
```bash
Host: email-smtp.[region].amazonaws.com
Port: 587
Encryption: tls
需要配置：
- AWS Region
- AWS Access Key
- AWS Secret Key
```

#### Mailgun
```bash
Host: smtp.mailgun.org
Port: 587
Encryption: tls
需要配置：
- Mailgun Domain
- Mailgun API Key
```

## 使用方法

### 1. 配置 SMTP

#### Microsoft 365 配置示例：
```bash
./scripts/smtp/smtp.sh config microsoft365
```

#### Gmail 配置示例：
```bash
./scripts/smtp/smtp.sh config gmail
```

#### SendGrid 配置示例：
```bash
./scripts/smtp/smtp.sh config sendgrid
```

#### Amazon SES 配置示例：
```bash
./scripts/smtp/smtp.sh config ses
```

#### Mailgun 配置示例：
```bash
./scripts/smtp/smtp.sh config mailgun
```

#### 自定义 SMTP 配置：
```bash
./scripts/smtp/smtp.sh config custom
```

### 2. 测试配置

#### 测试连接：
```bash
./scripts/smtp/smtp.sh test connection
```

#### 发送测试邮件：
```bash
./scripts/smtp/smtp.sh test send test@example.com
```

### 3. 查看配置状态
```bash
./scripts/smtp/smtp.sh status
```

### 4. 发送邮件

#### 发送普通邮件：
```bash
./scripts/smtp/smtp_send.sh recipient@example.com "邮件主题" "邮件内容"
```

#### 发送带附件的邮件：
```bash
./scripts/smtp/smtp_send.sh recipient@example.com "邮件主题" "邮件内容" "/path/to/attachment.pdf"
```

## 日志管理

### 日志配置
```bash
LOG_FILE="/var/log/smtp.log"
LOG_LEVEL="info"      # debug|info|warn|error
```

### 日志格式
```
时间戳 [级别] 消息
```

### 日志级别
- ERROR: 错误信息
- WARN: 警告信息
- INFO: 普通信息
- DEBUG: 调试信息

## 故障排除

### 1. 连接问题
- 检查网络连接
- 验证服务器地址和端口
- 确认防火墙设置

### 2. 认证失败
- 验证用户名和密码
- 检查加密设置
- 确认服务商特殊要求（如 Gmail 的应用专用密码）

### 3. 发送失败
- 检查发件人地址格式
- 验证收件人地址
- 查看详细错误日志

### 4. 加密问题
- Microsoft 365 建议使用 none 加密
- 其他服务商建议使用 tls 加密
- 如遇问题，可尝试切换加密方式

## 最佳实践

### 1. 安全建议
- 定期更改密码
- 使用最小权限账号
- 启用适当的加密
- 保护配置文件权限

### 2. 性能优化
- 适当设置重试间隔
- 合理配置日志级别
- 定期清理日志文件

### 3. 监控建议
- 定期检查日志
- 监控发送成功率
- 关注错误模式

## 服务商特殊说明

### 1. Microsoft 365
- 推荐使用无加密配置
- 需要启用 SMTP AUTH
- 可能需要管理员授权

### 2. Gmail
- 必须使用应用专用密码
- 需要启用两步验证
- 必须使用 TLS 加密

### 3. Amazon SES
- 需要在 AWS Console 验证发件人域名
- 新账号可能在沙箱模式
- 注意发送配额限制

### 4. SendGrid
- 建议使用 API Key 而非密码
- 需要验证发件人身份
- 提供详细的发送统计

### 5. Mailgun
- 需要验证域名
- 免费账号有发送限制
- 提供详细的日志和统计 