# LEMP Stack Installer for Magento

这是一个用于在Debian/Ubuntu系统上准备LEMP（Linux, Nginx, MariaDB, PHP）环境的脚本集合，专门为 Magento 2 电商平台优化配置。本工具仅负责环境配置，不包含 Magento 2 的安装过程。

## 功能特点

- 自动安装和配置 Nginx、MariaDB、PHP 8.2
- 针对 Magento 2 优化的 Nginx 配置
- MariaDB 数据库自动配置
- PHP-FPM 优化配置
- 完整的错误处理和日志记录
- 自动备份功能
- 安全检查工具
- 性能优化工具

## 系统要求

- Debian 11+ 或 Ubuntu 22.04+
- 至少 2GB RAM（建议用于生产环境的服务器配置更高）
- 至少 20GB 磁盘空间
- root 访问权限

## 使用方法

### 1. 基础安装

安装LEMP环境：

```bash
sudo ./scripts/install.sh
```

### 2. 数据库配置

配置MariaDB：

```bash
sudo ./scripts/configure_mysql.sh <db_name> <db_user> <db_password> <root_password>
```

### 3. Web服务器配置

配置Nginx虚拟主机：

```bash
sudo ./scripts/configure_vhost.sh <domain> <magento_root> <magento_mode>
```

删除虚拟主机配置：

```bash
sudo ./scripts/remove_vhost.sh <domain>
```

虚拟主机配置参数说明：
- domain: 网站域名（例如：magento.example.com）
- magento_root: Magento 安装路径（例如：/var/www/magento）
- magento_mode: Magento 运行模式（developer/production）

删除虚拟主机时，脚本会：
1. 删除 Nginx 相关配置文件和日志
2. 删除 PHP-FPM 相关配置
3. 恢复默认的 PHP-FPM 配置
4. 重启相关服务

注意：删除虚拟主机配置不会删除网站文件。

### 4. 备份

执行系统备份：

```bash
sudo ./scripts/backup.sh <magento_root> <db_name> <db_user> <db_password>
```

### 5. 安全检查

运行安全检查：

```bash
sudo ./scripts/security_check.sh
```

### 6. 性能优化

优化系统性能：

```bash
sudo ./scripts/optimize.sh
```

### 7. ModSecurity WAF（可选）

ModSecurity 是一个开源的 Web 应用防火墙(WAF)，可以提供额外的安全保护。

安装 ModSecurity：
```bash
sudo ./scripts/modsecurity.sh install
```

管理 ModSecurity：
```bash
# 检查状态
sudo ./scripts/modsecurity.sh status

# 启用
sudo ./scripts/modsecurity.sh enable

# 禁用
sudo ./scripts/modsecurity.sh disable

# 卸载
sudo ./scripts/modsecurity.sh uninstall
```

ModSecurity 默认配置：
- 使用 OWASP ModSecurity 核心规则集(CRS)
- 自动放行 Magento 后台路径
- 可以通过启用/禁用命令随时切换
- 在 Nginx 错误日志中记录规则命中情况

### 8. Fail2ban 入侵防御（可选）

Fail2ban 是一个入侵防御系统，可以保护服务器免受暴力破解攻击。

安装 Fail2ban：
```bash
sudo ./scripts/fail2ban.sh install
```

管理 Fail2ban：
```bash
# 检查状态
sudo ./scripts/fail2ban.sh status

# 解封特定IP
sudo ./scripts/fail2ban.sh unban <ip_address>

# 卸载
sudo ./scripts/fail2ban.sh uninstall
```

Fail2ban 默认配置：
- SSH 登录保护（3次失败尝试后封禁）
- Nginx 基本认证保护
- Nginx 登录保护（5次失败尝试后封禁）
- Nginx 请求限制保护
- Magento 管理员登录保护（5次失败尝试后封禁）
- 默认封禁时间：1小时
- 在10分钟内统计失败次数

注意：ModSecurity 和 Fail2ban 可以同时使用，它们在不同层面提供保护：
- ModSecurity：应用层防火墙，防御 Web 攻击
- Fail2ban：网络层防御，防止暴力破解

### 参数说明

MariaDB配置：
- db_name: 数据库名称
- db_user: 数据库用户名
- db_password: 数据库密码
- root_password: MariaDB root密码

Nginx虚拟主机配置：
- domain: 网站域名
- magento_root: Magento安装路径
- magento_mode: Magento运行模式（developer/production）

备份参数：
- magento_root: Magento安装路径
- db_name: 要备份的数据库名称
- db_user: 数据库用户名
- db_password: 数据库密码

## 目录结构

```
.
├── backup/         # 备份文件目录
├── config/         # 配置文件目录
├── docs/          # 文档
├── logs/          # 日志文件
├── scripts/       # 安装脚本
│   ├── install.sh           # LEMP环境安装脚本
│   ├── configure_mysql.sh   # MySQL配置脚本
│   ├── configure_vhost.sh   # Nginx虚拟主机配置脚本
│   ├── remove_vhost.sh      # Nginx虚拟主机删除脚本
│   ├── backup.sh           # 备份脚本
│   ├── security_check.sh   # 安全检查脚本
│   └── optimize.sh         # 性能优化脚本
├── templates/     # 配置模板
├── tests/         # 测试文件
└── tools/         # 工具脚本
```

## 注意事项

1. 所有脚本必须以root权限运行
2. 在生产环境中使用前请先在测试环境验证
3. 请确保备份所有重要数据
4. 安装完成后请及时修改所有默认密码
5. 定期运行安全检查和性能优化脚本
6. 根据实际负载调整性能参数
7. 本工具仅配置运行环境，Magento 2 需要单独安装

## 性能优化

性能优化脚本会自动根据系统配置调整以下参数：

- PHP-FPM进程数和内存限制
- Nginx worker进程和连接数
- MariaDB缓冲区和线程设置
- 系统内核参数
- OPcache配置
- FastCGI缓存

## 安全检查

安全检查脚本会检查以下方面：

- PHP配置安全
- Nginx配置安全
- MariaDB用户和权限
- 文件系统权限
- 系统安全设置
- 开放端口

## 故障排除

如果遇到问题，请检查以下日志文件：

- Nginx错误日志: `/var/log/nginx/error.log`
- PHP-FPM错误日志: `/var/log/php8.2-fpm.log`
- MariaDB错误日志: `/var/log/mysql/error.log`
- 慢查询日志: `/var/log/mysql/slow.log`

## 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 许可证

MIT License
