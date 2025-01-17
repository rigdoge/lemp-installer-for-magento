# Telegram 通知配置指南

## 1. 创建 Telegram Bot

1. 在 Telegram 中搜索 `@BotFather`
2. 发送命令 `/newbot` 
3. 按提示设置:
   - 输入 bot 名称
   - 输入 bot 用户名（必须以 bot 结尾）
4. 保存 BotFather 返回的 API Token

## 2. 配置通知脚本

运行配置命令：
```bash
./scripts/telegram/telegram.sh configure
```

按提示进行操作：
1. 输入之前保存的 Bot Token
2. 给你的 bot 发送一条消息（随便发什么都可以）
3. 运行命令获取 Chat ID：
   ```bash
   curl https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```
4. 在返回的 JSON 中找到 `"chat":{"id":XXXXXX}` 中的数字
5. 输入找到的 Chat ID
6. 如果配置成功，会收到一条测试消息

## 3. 发送测试消息

```bash
./scripts/telegram/telegram.sh send "这是一条测试消息"
```

## 4. 支持的功能

1. 基本文本消息
```bash
./scripts/telegram/telegram.sh send "普通文本消息"
```

2. HTML 格式消息
```bash
./scripts/telegram/telegram.sh send "<b>粗体</b> <i>斜体</i> <code>代码</code>"
```

3. 监控告警示例
```bash
./scripts/telegram/telegram.sh send "🔴 错误警告
服务: RabbitMQ
状态: 队列堆积
详情: order_processing 队列有 1000+ 消息待处理
时间: $(date '+%Y-%m-%d %H:%M:%S')"
```

## 5. 安全注意事项

1. 配置文件权限
   - telegram.conf 文件权限设置为 600
   - 只有 root 用户可读写

2. Bot Token 安全
   - 不要在公共场合分享 Bot Token
   - 定期检查 Bot 活动状态

## 6. 故障排除

1. 无法发送消息
   - 检查网络连接
   - 验证 Bot Token 是否正确
   - 确认 Chat ID 是否正确

2. 消息格式错误
   - 检查是否包含特殊字符
   - HTML 格式必须正确闭合标签

## 7. 最佳实践

1. 告警级别
   - 🔴 严重错误
   - 🟡 警告信息
   - 🟢 正常状态
   - ℹ️ 一般信息

2. 消息格式建议
   ```
   [级别图标] 标题
   服务: xxx
   状态: xxx
   详情: xxx
   时间: xxx
   ```

3. 定期测试
   - 建议每周测试一次通知功能
   - 确保 Bot Token 未过期 