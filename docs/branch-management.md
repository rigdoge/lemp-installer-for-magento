# 分支管理说明文档

## 仓库分支说明

### 主线分支 (main)
- 用途：稳定版本，包含基础的 LEMP 环境配置功能
- 主要功能：
  - Nginx、MariaDB、PHP 安装和配置
  - SSL 证书配置
  - 虚拟主机管理
  - 安全配置（ModSecurity、Fail2ban）
  - OpenSearch 配置

### 监控系统分支 (feature/monitoring-system)
- 用途：扩展功能，包含监控系统相关功能
- 额外功能：
  - RabbitMQ 监控
  - 系统状态监控
  - 告警系统
  - 监控面板

## 版本说明
- v1.1.0：基础 LEMP 环境配置
- v1.2：增加 OpenSearch SSL 支持

## 使用方法

### 1. 克隆仓库
```bash
git clone https://github.com/rigdoge/lemp-installer-for-magento.git
cd lemp-installer-for-magento
```

### 2. 切换分支

#### 使用主线版本（基础功能）
```bash
git checkout main
```

#### 使用监控系统版本
```bash
git checkout feature/monitoring-system
```

#### 使用特定版本
```bash
# 使用 v1.2 版本
git checkout v1.2
```

### 3. 更新代码
```bash
# 更新当前分支
git pull

# 更新特定分支
git pull origin feature/monitoring-system
```

### 4. 分支切换注意事项
1. 切换分支前请确保当前工作区干净
2. 如遇到切换问题，可以：
   ```bash
   # 保存当前修改
   git stash
   
   # 切换分支
   git checkout 目标分支
   
   # 恢复修改（如需要）
   git stash pop
   ```

### 5. 功能对比

#### 主线分支功能
- LEMP 环境安装
- 数据库配置
- Web 服务器配置
- SSL 证书配置
- 安全加固
- 性能优化

#### 监控系统分支额外功能
- RabbitMQ 监控
- 系统状态监控
- 监控管理命令
- Web 监控面板
- 告警系统

## 推荐使用场景

### 使用主线分支的情况
1. 仅需要基础的 LEMP 环境
2. 不需要监控功能
3. 系统资源有限

### 使用监控系统分支的情况
1. 需要完整的监控功能
2. 需要系统状态实时监控
3. 需要自动告警功能
4. 有足够的系统资源

## 故障排除

### 分支切换问题
```bash
# 如果遇到切换冲突
git reset --hard
git clean -fd
git checkout 目标分支
```

### 更新问题
```bash
# 如果遇到更新冲突
git fetch origin
git reset --hard origin/分支名
```

### 版本回退
```bash
# 回退到特定版本
git checkout v1.1.0
``` 