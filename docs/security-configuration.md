# 安全配置指南

## 概述

本文档包含两个主要的安全组件配置：
1. ModSecurity WAF（Web应用防火墙）
2. Fail2ban（入侵防御系统）

## ModSecurity WAF

### 1. 安装

```bash
# 安装 ModSecurity
sudo ./scripts/modsecurity.sh install
```

安装脚本会：
1. 安装 ModSecurity 模块
2. 安装 OWASP ModSecurity 核心规则集(CRS)
3. 配置基本规则
4. 启用 Nginx 集成

### 2. 配置

#### 基础配置
位置：`/etc/nginx/modsecurity/modsecurity.conf`
```nginx
# 启用 ModSecurity
SecRuleEngine On

# 设置默认动作
SecDefaultAction "phase:2,deny,log,status:403"

# 请求体限制
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072

# 响应体限制
SecResponseBodyLimit 524288
```

#### 规则配置
位置：`/etc/nginx/modsecurity/crs/crs-setup.conf`
```nginx
# 设置异常评分阈值
SecAction \
  "id:900000,\
   phase:1,\
   nolog,\
   pass,\
   t:none,\
   setvar:tx.paranoia_level=1,\
   setvar:tx.anomaly_score_threshold=5"
```

### 3. 管理命令

```bash
# 检查状态
sudo ./scripts/modsecurity.sh status

# 启用保护
sudo ./scripts/modsecurity.sh enable

# 禁用保护
sudo ./scripts/modsecurity.sh disable

# 卸载
sudo ./scripts/modsecurity.sh uninstall
```

### 4. 自定义规则

位置：`/etc/nginx/modsecurity/custom-rules.conf`
```nginx
# 保护 Magento 后台
SecRule REQUEST_URI "@beginsWith /admin" \
    "id:1000,\
    phase:1,\
    deny,\
    status:403,\
    msg:'Unauthorized access to admin area',\
    chain"
    SecRule REMOTE_ADDR "!@ipMatch 192.168.1.0/24"

# 防止 SQL 注入
SecRule REQUEST_COOKIES|!REQUEST_COOKIES:/__utm/|REQUEST_COOKIES_NAMES|ARGS_NAMES|ARGS|XML:/* "@detectSQLi" \
    "id:1001,\
    phase:2,\
    deny,\
    status:403,\
    msg:'SQL Injection Attack'"
```

### 5. 日志配置

```nginx
# 启用审计日志
SecAuditEngine RelevantOnly
SecAuditLog /var/log/modsec_audit.log

# 设置日志格式
SecAuditLogParts ABCFHZ
```

### 6. 性能优化

```nginx
# 优化规则处理
SecRuleUpdateTargetById 942100 "!REQUEST_COOKIES:/^(?:wordpress_test_cookie)$/"
SecRuleRemoveById 981172 

# 缓存设置
SecDataDir /tmp/modsecurity/data
SecTmpDir /tmp/modsecurity/tmp
```

## Fail2ban

### 1. 安装

```bash
# 安装 Fail2ban
sudo ./scripts/fail2ban.sh install
```

### 2. 配置

#### 主配置文件
位置：`/etc/fail2ban/jail.local`
```ini
[DEFAULT]
# 封禁时间（秒）
bantime = 3600

# 查找时间（秒）
findtime = 600

# 最大尝试次数
maxretry = 5

# 忽略的IP
ignoreip = 127.0.0.1/8 ::1

# 动作
banaction = iptables-multiport
```

#### Magento 保护配置
```ini
[magento-admin]
enabled = true
filter = magento-admin
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 600
bantime = 3600
port = http,https
```

### 3. 管理命令

```bash
# 检查状态
sudo ./scripts/fail2ban.sh status

# 查看被封禁的IP
sudo fail2ban-client status magento-admin

# 解封IP
sudo ./scripts/fail2ban.sh unban <ip_address>

# 手动封禁IP
sudo fail2ban-client set magento-admin banip <ip_address>
```

### 4. 自定义过滤器

#### Magento 管理员登录
位置：`/etc/fail2ban/filter.d/magento-admin.conf`
```ini
[Definition]
failregex = ^<HOST> .* POST .*/admin/admin/index/index/.* 403
            ^<HOST> .* POST .*/admin/.* 401
ignoreregex =
```

#### API 限制
位置：`/etc/fail2ban/filter.d/magento-api.conf`
```ini
[Definition]
failregex = ^<HOST> .* POST .*/rest/V1/.* 401
ignoreregex =
```

### 5. 告警配置

#### 邮件通知
位置：`/etc/fail2ban/action.d/mail-whois.conf`
```ini
[Definition]
actionstart = printf %%b "Service $(echo `date`): fail2ban starting" | mail -s "[Fail2Ban] Started on `uname -n`" <your-email>
actionstop = printf %%b "Service $(echo `date`): fail2ban stopped" | mail -s "[Fail2Ban] Stopped on `uname -n`" <your-email>
actionban = printf %%b "Host: <ip>\n Banned on: `date`" | mail -s "[Fail2Ban] Ban <ip>" <your-email>
actionunban = printf %%b "Host: <ip>\n Unbanned on: `date`" | mail -s "[Fail2Ban] Unban <ip>" <your-email>
```

## 集成配置

### 1. ModSecurity 和 Fail2ban 协同工作

```bash
# 创建 ModSecurity 日志过滤器
sudo ./scripts/create_modsec_filter.sh

# 配置 Fail2ban 使用 ModSecurity 日志
sudo ./scripts/configure_fail2ban_modsec.sh
```

### 2. 日志聚合

```bash
# 配置集中日志
sudo ./scripts/configure_central_logging.sh

# 启用日志轮转
sudo ./scripts/configure_log_rotation.sh
```

## 最佳实践

### 1. ModSecurity 最佳实践
- 从低paranoia级别开始
- 逐步启用规则
- 定期更新规则集
- 监控误报情况
- 根据应用需求调整规则

### 2. Fail2ban 最佳实践
- 设置合理的封禁时间
- 配置白名单IP
- 定期检查日志
- 及时处理误封
- 保持规则更新

### 3. 安全监控
- 定期检查安全日志
- 配置告警通知
- 记录安全事件
- 定期安全审计
- 更新安全策略

## 故障排除

### 1. ModSecurity 问题

```bash
# 检查 ModSecurity 状态
sudo nginx -t
tail -f /var/log/modsec_audit.log

# 常见问题解决
sudo ./scripts/modsecurity.sh troubleshoot
```

### 2. Fail2ban 问题

```bash
# 检查 Fail2ban 状态
sudo systemctl status fail2ban
sudo fail2ban-client ping

# 测试规则
sudo fail2ban-regex /var/log/nginx/access.log /etc/fail2ban/filter.d/magento-admin.conf
```

### 3. 紧急情况处理

```bash
# 禁用 ModSecurity
sudo ./scripts/modsecurity.sh disable

# 停止 Fail2ban
sudo systemctl stop fail2ban

# 清除所有封禁
sudo ./scripts/fail2ban.sh clear-all
``` 