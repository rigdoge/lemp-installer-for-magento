#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 命令行参数处理
ACTION=$1
if [ -z "$ACTION" ]; then
    ACTION="install"
fi

# 检查系统
if [ ! -f /etc/debian_version ]; then
    echo -e "${RED}此脚本仅支持 Debian/Ubuntu 系统${NC}"
    exit 1
fi

# 设置安装目录
PANEL_DIR="/opt/lemp-manager"

# 安装函数
install() {
    echo -e "${BLUE}开始安装 LEMP Stack 管理面板...${NC}"

    # 检查 Node.js 环境
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}未检测到 Node.js，正在安装...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    # 创建安装目录
    sudo mkdir -p "$PANEL_DIR"
    sudo chown -R $USER:$USER "$PANEL_DIR"

    # 清理旧文件
    echo "清理旧文件..."
    rm -rf "$PANEL_DIR"/*

    # 创建目录结构
    mkdir -p "$PANEL_DIR"/{frontend,backend}

    # 安装前端依赖
    echo "安装前端依赖..."
    cd "$PANEL_DIR/frontend"
    npm init -y
    npm install --save react react-dom react-admin ra-data-json-server @mui/material @mui/icons-material @emotion/react @emotion/styled

    # 安装后端依赖
    echo "安装后端依赖..."
    cd "$PANEL_DIR/backend"
    npm init -y
    npm install --save express express-ws

    echo -e "${GREEN}安装完成！${NC}"
}

# 启动函数
start() {
    echo -e "${BLUE}启动 LEMP Stack 管理面板...${NC}"
    sudo systemctl start lemp-panel
    echo -e "${GREEN}服务已启动！${NC}"
}

# 停止函数
stop() {
    echo -e "${BLUE}停止 LEMP Stack 管理面板...${NC}"
    sudo systemctl stop lemp-panel
    echo -e "${GREEN}服务已停止！${NC}"
}

# 重启函数
restart() {
    echo -e "${BLUE}重启 LEMP Stack 管理面板...${NC}"
    sudo systemctl restart lemp-panel
    echo -e "${GREEN}服务已重启！${NC}"
}

# 状态函数
status() {
    echo -e "${BLUE}LEMP Stack 管理面板状态：${NC}"
    sudo systemctl status lemp-panel
}

# 卸载函数
uninstall() {
    echo -e "${RED}卸载 LEMP Stack 管理面板...${NC}"
    sudo systemctl stop lemp-panel
    sudo systemctl disable lemp-panel
    sudo rm -f /etc/systemd/system/lemp-panel.service
    sudo systemctl daemon-reload
    sudo rm -rf "$PANEL_DIR"
    echo -e "${GREEN}卸载完成！${NC}"
}

# 根据命令行参数执行相应的函数
case $ACTION in
    "install")
        install
        ;;
    "start")
        start
        ;;
    "stop")
        stop
        ;;
    "restart")
        restart
        ;;
    "status")
        status
        ;;
    "uninstall")
        uninstall
        ;;
    *)
        echo -e "${RED}未知命令: $ACTION${NC}"
        echo "可用命令: install, start, stop, restart, status, uninstall"
        exit 1
        ;;
esac 