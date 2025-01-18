#!/bin/bash

# 设置错误时退出
set -e

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 获取项目根目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 定义安装目录
INSTALL_DIR="$PROJECT_ROOT"
PANEL_DIR="$INSTALL_DIR"
LOG_DIR="$INSTALL_DIR/logs"

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用 root 用户运行此脚本${NC}"
        exit 1
    fi
}

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$INSTALL_DIR/config"
    chown -R $SUDO_USER:$SUDO_USER "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
}

# 安装系统依赖
install_dependencies() {
    echo -e "${GREEN}安装系统依赖...${NC}"
    # 检查并安装 Node.js
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    fi
}

# 安装 Web UI
install_web_ui() {
    echo -e "${GREEN}安装前端 UI...${NC}"
    
    # 安装依赖
    echo -e "${GREEN}安装 Node.js 依赖...${NC}"
    npm install

    # 构建应用
    echo -e "${GREEN}构建应用...${NC}"
    npx next build
}

# 安装后端服务
install_backend() {
    echo -e "${GREEN}安装后端服务...${NC}"
    cd "$PANEL_DIR/backend"

    # 安装依赖
    echo -e "${GREEN}安装后端依赖...${NC}"
    npm install
}

# 创建系统服务
create_services() {
    echo -e "${GREEN}创建系统服务...${NC}"
    
    # 安装 PM2
    npm install -g pm2
    
    # 创建前端服务
    cat > /etc/systemd/system/lemp-panel-frontend.service << EOF
[Unit]
Description=LEMP Panel Frontend
After=network.target

[Service]
Type=simple
User=$SUDO_USER
WorkingDirectory=$PROJECT_ROOT
Environment=NODE_ENV=production
Environment=PORT=3001
ExecStart=/usr/bin/npm run start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # 创建后端服务
    cat > /etc/systemd/system/lemp-panel-backend.service << EOF
[Unit]
Description=LEMP Panel Backend
After=network.target

[Service]
Type=simple
User=$SUDO_USER
WorkingDirectory=$PROJECT_ROOT/backend
Environment=NODE_ENV=production
Environment=PORT=3000
ExecStart=/usr/bin/pm2 start src/server.js --name lemp-panel-backend
ExecStop=/usr/bin/pm2 stop lemp-panel-backend
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载 systemd
    systemctl daemon-reload
    
    # 启用并启动服务
    systemctl enable lemp-panel-frontend
    systemctl enable lemp-panel-backend
    systemctl start lemp-panel-frontend
    systemctl start lemp-panel-backend
}

# 主函数
main() {
    check_root
    create_directories
    install_dependencies
    install_web_ui
    install_backend
    create_services
    
    echo -e "${GREEN}安装完成!${NC}"
    echo "前端面板地址: http://your-server-ip:3001"
    echo "后端API地址: http://your-server-ip:3000"
}

# 处理命令行参数
case "$1" in
    "install")
        main
        ;;
    *)
        echo "用法: $0 install"
        exit 1
        ;;
esac
