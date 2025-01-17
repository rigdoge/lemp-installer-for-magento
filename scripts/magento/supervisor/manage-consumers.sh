#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本必须以root权限运行${NC}"
   exit 1
fi

# 检查supervisor是否安装
if ! command -v supervisord &> /dev/null; then
    echo -e "${YELLOW}正在安装supervisor...${NC}"
    apt-get update
    apt-get install -y supervisor
fi

# 创建日志目录
mkdir -p /var/log/magento/consumers

# 设置日志目录权限
chown -R doge:doge /var/log/magento
chmod -R 755 /var/log/magento

# 复制配置文件
cp "$SCRIPT_DIR/magento-consumers.conf" /etc/supervisor/conf.d/

# 重新加载supervisor配置
supervisorctl reread
supervisorctl update

# 启动所有消费者
supervisorctl start magento_consumers:*

# 显示状态
echo -e "${GREEN}所有消费者已启动。当前状态：${NC}"
supervisorctl status magento_consumers:*

# 使用说明
echo -e "\n${YELLOW}使用说明：${NC}"
echo "1. 启动所有消费者：supervisorctl start magento_consumers:*"
echo "2. 停止所有消费者：supervisorctl stop magento_consumers:*"
echo "3. 重启所有消费者：supervisorctl restart magento_consumers:*"
echo "4. 查看状态：supervisorctl status magento_consumers:*"
echo "5. 查看特定消费者日志：tail -f /var/log/magento/consumers/[consumer_name].log" 