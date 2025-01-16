# Changelog

## [1.1.0] - 2025-01-16

### Added
- 支持自定义 PHP-FPM 和 Nginx 用户（默认使用 doge 用户）
- 添加 PHP-FPM 日志配置和自动创建
- 添加服务状态检查和日志显示功能

### Changed
- 使用 Magento 自带的 nginx.conf.sample 配置
- 优化 PHP-FPM 池配置
- 改进错误处理和日志输出

### Fixed
- 修复 PHP-FPM socket 权限问题
- 修复 systemctl status 命令分页问题
- 修复日志文件权限问题 