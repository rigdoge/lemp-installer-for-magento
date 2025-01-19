# LEMP Stack Installer for Magento

自动化安装和配置 LEMP (Linux, Nginx, MySQL/Percona, PHP) 环境，专为 Magento 2.4.7 优化。

## 项目结构

```
.
├── src/                    # 源代码目录
│   ├── scripts/           # Shell 脚本
│   └── config/            # 配置文件
├── ansible/               # Ansible 自动化配置
│   ├── playbooks/        # Playbook 文件
│   ├── roles/            # 角色定义
│   ├── inventory/        # 主机清单
│   ├── group_vars/       # 组变量
│   └── host_vars/        # 主机变量
└── app/                  # Web 管理界面
    └── ...               # Next.js 应用程序
```

## 功能特点

1. 自动化部署
   - 环境检查和准备
   - LEMP 环境安装
   - Magento 优化配置
   - 监控系统部署

2. 环境管理
   - Nginx 1.24
   - PHP 8.2
   - Percona 8.0
   - Redis 7.2
   - Varnish 7.5
   - OpenSearch 2.12
   - RabbitMQ 3.13

3. 系统监控
   - Prometheus
   - Grafana
   - Alertmanager
   - OpenSearch

4. Web 管理界面
   - 系统状态监控
   - 日志管理
   - 性能分析
   - 告警通知

## 安装要求

- 操作系统: Debian/Ubuntu
- CPU: 2+ 核心
- 内存: 4GB+
- 磁盘: 20GB+
- 网络: 公网 IP

## 快速开始

1. 环境检查
```bash
./src/scripts/pre-check.sh
```

2. 安装 LEMP 环境
```bash
ansible-playbook ansible/playbooks/main.yml
```

3. 启动 Web 管理界面
```bash
cd app && npm run build && npm start
```

## 配置说明

1. Ansible 配置
   - `ansible/ansible.cfg`: Ansible 主配置
   - `ansible/inventory/hosts`: 主机清单

2. 环境配置
   - `src/config/`: 各组件配置文件
   - `ansible/group_vars/`: 环境变量

## 版本历史

- v1.6.0: 重构项目结构，整合 Ansible 自动化
- v1.2.x: 实现基础功能和 Web 界面
- v1.0.x: 初始版本，基础脚本

## 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交变更
4. 发起 Pull Request

## 许可证

MIT
