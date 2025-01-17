# 监控系统说明文档

## 系统概述

监控系统是一个模块化的插件系统，用于监控 LEMP 环境中的各个组件。系统采用插件式架构，允许动态添加和移除监控模块。

## 目录结构

```
scripts/plugins/monitoring/
├── available/          # 可用的监控模块
├── enabled/           # 已启用的监控模块（软链接）
└── commands/          # 管理命令
    ├── list.sh       # 列出所有监控
    ├── enable.sh     # 启用监控
    ├── disable.sh    # 禁用监控
    └── status.sh     # 查看状态
```

## 基础命令

### 1. list.sh - 列出监控模块

显示所有可用的监控模块及其状态。

**用法：**
```bash
./scripts/plugins/monitoring/commands/list.sh
```

**输出示例：**
```
Available Monitors:
====================
  ✓ rabbitmq (enabled)
  × php-fpm (disabled)
```

**返回值：**
- 0: 成功
- 1: 目录不存在

### 2. enable.sh - 启用监控

启用指定的监控模块。

**用法：**
```bash
./scripts/plugins/monitoring/commands/enable.sh <monitor-name>
```

**参数：**
- monitor-name: 要启用的监控模块名称

**示例：**
```bash
./scripts/plugins/monitoring/commands/enable.sh rabbitmq
```

**功能：**
- 检查监控模块是否存在
- 创建软链接到 enabled 目录
- 执行初始化脚本（如果存在）

**返回值：**
- 0: 成功或已启用
- 1: 错误（参数缺失、模块不存在等）

### 3. disable.sh - 禁用监控

禁用指定的监控模块。

**用法：**
```bash
./scripts/plugins/monitoring/commands/disable.sh <monitor-name>
```

**参数：**
- monitor-name: 要禁用的监控模块名称

**示例：**
```bash
./scripts/plugins/monitoring/commands/disable.sh rabbitmq
```

**功能：**
- 检查监控模块是否存在
- 执行停止脚本（如果存在）
- 删除软链接

**返回值：**
- 0: 成功或已禁用
- 1: 错误（参数缺失、模块不存在等）

### 4. status.sh - 查看状态

显示所有已启用监控模块的当前状态。

**用法：**
```bash
./scripts/plugins/monitoring/commands/status.sh
```

**状态码含义：**
- 0: 正常运行（绿色）
- 1: 错误（红色）
- 2: 警告（黄色）
- 其他: 未知状态

**输出示例：**
```
Monitoring Status:
==================
Monitor: rabbitmq
Status: Running
Queue size: 0
Consumers: 2

Monitor: php-fpm
Status: Warning
High memory usage: 85%
```

## 监控模块开发指南

### 模块文件结构

每个监控模块应包含以下文件：
```
available/
└── module-name.monitor     # 主监控脚本
└── module-name.monitor.init    # 初始化脚本（可选）
└── module-name.monitor.stop    # 停止脚本（可选）
└── module-name.monitor.status  # 状态检查脚本（可选）
```

### 返回值规范

状态检查脚本应遵循以下返回值规范：
- 0: 正常运行
- 1: 错误状态
- 2: 警告状态

### 输出规范

状态检查脚本的输出应该是结构化的，便于读取和解析：
```
Key1: Value1
Key2: Value2
Message: Detailed status message
```

## 注意事项

1. 所有脚本必须具有可执行权限
2. 初始化和停止脚本是可选的
3. 状态检查脚本应该是非阻塞的
4. 错误信息应该明确且有用
5. 所有脚本都应该有适当的错误处理

## 安全建议

1. 定期检查监控日志
2. 及时响应警告信息
3. 定期更新监控脚本
4. 保护监控配置文件
5. 限制对监控命令的访问权限 