#!/bin/bash

# 设置错误时退出
set -e

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 定义安装目录
INSTALL_DIR="/opt/lemp-manager"
PANEL_DIR="$INSTALL_DIR/panel"
LOG_DIR="/var/log/lemp-panel"

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用 root 用户运行此脚本${NC}"
        exit 1
    fi
}

# 创建必要的目录
create_directories() {
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$PANEL_DIR"
    mkdir -p "$LOG_DIR"
    # 前端目录
    mkdir -p "$PANEL_DIR/frontend/src/app"
    mkdir -p "$PANEL_DIR/frontend/src/components"
    # 后端目录
    mkdir -p "$PANEL_DIR/backend/src/modules/services"
    mkdir -p "$PANEL_DIR/backend/src/modules/system"
    mkdir -p "$PANEL_DIR/backend/src/core"
    mkdir -p "$PANEL_DIR/backend/src/config"
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
    cd "$PANEL_DIR/frontend"
    
    # 创建 package.json
    cat > package.json << EOF
{
  "name": "lemp-manager",
  "version": "1.4.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3001",
    "build": "next build",
    "start": "next start -p 3001"
  },
  "dependencies": {
    "next": "14.0.4",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-admin": "^4.16.0",
    "ra-data-simple-rest": "^4.16.0",
    "@mui/material": "^5.15.0",
    "@mui/icons-material": "^5.15.0",
    "@emotion/react": "^11.11.0",
    "@emotion/styled": "^11.11.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "typescript": "^5.0.0"
  }
}
EOF

    # 创建 tsconfig.json
    cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

    # 创建根布局文件
    cat > src/app/layout.tsx << EOF
import React from 'react';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <title>LEMP Stack Manager</title>
        <meta name="description" content="LEMP Stack Manager for Magento" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </head>
      <body style={{ margin: 0 }}>{children}</body>
    </html>
  );
}
EOF

    # 创建 global.css
    cat > src/app/globals.css << EOF
* {
  box-sizing: border-box;
  padding: 0;
  margin: 0;
}

html,
body {
  max-width: 100vw;
  overflow-x: hidden;
  height: 100%;
}

body {
  background: #121212;
  color: #fff;
}
EOF

    # 更新主页面组件
    cat > src/app/page.tsx << EOF
'use client';

import dynamic from 'next/dynamic';
import './globals.css';

const AdminApp = dynamic(() => import('@/components/AdminApp'), { 
  ssr: false,
  loading: () => <div>Loading...</div>
});

export default function Page() {
    return <AdminApp />;
}
EOF

    # 创建 AdminApp 组件
    mkdir -p src/components
    cat > src/components/AdminApp.tsx << EOF
import React from 'react';
import { Admin, Resource } from 'react-admin';
import simpleRestProvider from 'ra-data-simple-rest';
import { ServiceList } from '@/components/services/ServiceList';

const dataProvider = simpleRestProvider('/api');

export default function AdminApp() {
    return (
        <Admin
            dataProvider={dataProvider}
            darkTheme={{ palette: { mode: 'dark' } }}
            defaultTheme="dark"
        >
            <Resource
                name="services"
                list={ServiceList}
            />
        </Admin>
    );
}
EOF

    # 创建 ServiceList 组件
    mkdir -p src/components/services
    cat > src/components/services/ServiceList.tsx << EOF
import React from 'react';
import {
    List,
    Datagrid,
    TextField,
    BooleanField,
    DateField,
} from 'react-admin';

export const ServiceList = () => (
    <List>
        <Datagrid>
            <TextField source="id" />
            <TextField source="name" />
            <TextField source="status" />
            <BooleanField source="isRunning" />
            <DateField source="lastCheck" />
        </Datagrid>
    </List>
);
EOF

    # 安装依赖
    echo -e "${GREEN}安装 Node.js 依赖...${NC}"
    npm install

    # 构建应用
    echo -e "${GREEN}构建应用...${NC}"
    npm run build
}

# 安装后端服务
install_backend() {
    echo -e "${GREEN}安装后端服务...${NC}"
    cd "$PANEL_DIR/backend"

    # 创建后端 package.json
    cat > package.json << EOF
{
  "name": "lemp-manager-backend",
  "version": "1.4.0",
  "private": true,
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "express-ws": "^5.0.2",
    "cors": "^2.8.5",
    "winston": "^3.11.0",
    "systeminformation": "^5.21.22"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
EOF

    # 创建主服务器文件
    cat > src/server.js << EOF
const express = require('express');
const cors = require('cors');
const expressWs = require('express-ws');
const { setupLogger } = require('./core/logger');
const { setupRoutes } = require('./core/routes');
const config = require('./config');

const app = express();
expressWs(app);

// 设置日志
const logger = setupLogger();

// 中间件
app.use(cors());
app.use(express.json());

// 请求日志
app.use((req, res, next) => {
    logger.info(\`\${req.method} \${req.url}\`);
    next();
});

// 设置路由
setupRoutes(app);

// 错误处理
app.use((err, req, res, next) => {
    logger.error(err.stack);
    res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    logger.info(\`Backend server running on port \${PORT}\`);
});
EOF

    # 创建日志模块
    cat > src/core/logger.js << EOF
const winston = require('winston');
const path = require('path');

function setupLogger() {
    return winston.createLogger({
        level: 'info',
        format: winston.format.combine(
            winston.format.timestamp(),
            winston.format.json()
        ),
        transports: [
            new winston.transports.File({ 
                filename: path.join(process.env.LOG_DIR || 'logs', 'error.log'), 
                level: 'error' 
            }),
            new winston.transports.File({ 
                filename: path.join(process.env.LOG_DIR || 'logs', 'combined.log')
            }),
            new winston.transports.Console({
                format: winston.format.combine(
                    winston.format.colorize(),
                    winston.format.simple()
                )
            })
        ]
    });
}

module.exports = { setupLogger };
EOF

    # 创建路由设置模块
    cat > src/core/routes.js << EOF
const servicesRouter = require('../modules/services/router');
const systemRouter = require('../modules/system/router');

function setupRoutes(app) {
    app.use('/api/services', servicesRouter);
    app.use('/api/system', systemRouter);
}

module.exports = { setupRoutes };
EOF

    # 创建配置模块
    cat > src/config/index.js << EOF
module.exports = {
    services: {
        nginx: {
            name: 'Nginx',
            configPath: '/etc/nginx/nginx.conf',
            logPath: '/var/log/nginx/error.log'
        },
        php: {
            name: 'PHP-FPM',
            configPath: '/etc/php/8.1/fpm/php.ini',
            logPath: '/var/log/php8.1-fpm.log'
        },
        mysql: {
            name: 'Percona Server',
            configPath: '/etc/mysql/my.cnf',
            logPath: '/var/log/mysql/error.log'
        }
    }
};
EOF

    # 创建服务模块路由
    cat > src/modules/services/router.js << EOF
const express = require('express');
const router = express.Router();
const { getServices, getServiceStatus, controlService } = require('./controller');

router.get('/', getServices);
router.get('/:id/status', getServiceStatus);
router.post('/:id/control', controlService);

module.exports = router;
EOF

    # 创建服务模块控制器
    cat > src/modules/services/controller.js << EOF
const { exec } = require('child_process');
const util = require('util');
const config = require('../../config');

const execAsync = util.promisify(exec);

async function getServices(req, res) {
    try {
        const services = Object.entries(config.services).map(([id, service]) => ({
            id,
            ...service
        }));
        res.json(services);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}

async function getServiceStatus(req, res) {
    try {
        const { id } = req.params;
        const { stdout } = await execAsync(\`systemctl status \${id}\`);
        const isActive = stdout.includes('active (running)');
        res.json({ id, status: isActive ? 'running' : 'stopped' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}

async function controlService(req, res) {
    try {
        const { id } = req.params;
        const { action } = req.body;
        
        if (!['start', 'stop', 'restart'].includes(action)) {
            return res.status(400).json({ error: 'Invalid action' });
        }

        await execAsync(\`systemctl \${action} \${id}\`);
        res.json({ message: \`Service \${id} \${action}ed successfully\` });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}

module.exports = {
    getServices,
    getServiceStatus,
    controlService
};
EOF

    # 安装依赖
    echo -e "${GREEN}安装后端依赖...${NC}"
    npm install
}

# 创建系统服务
create_service() {
    echo -e "${GREEN}创建系统服务...${NC}"
    
    # 前端服务
    cat > /etc/systemd/system/lemp-panel-frontend.service << EOF
[Unit]
Description=LEMP Stack Manager Panel Frontend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PANEL_DIR/frontend
Environment=NODE_ENV=production
ExecStart=$(which npm) start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # 后端服务
    cat > /etc/systemd/system/lemp-panel-backend.service << EOF
[Unit]
Description=LEMP Stack Manager Panel Backend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PANEL_DIR/backend
Environment=NODE_ENV=production
Environment=LOG_DIR=/var/log/lemp-panel
ExecStart=$(which npm) start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable lemp-panel-frontend
    systemctl enable lemp-panel-backend
    systemctl start lemp-panel-frontend
    systemctl start lemp-panel-backend
}

# 安装面板
install_panel() {
    check_root
    create_directories
    install_dependencies
    install_web_ui
    install_backend
    create_service
    
    echo -e "${GREEN}安装完成!${NC}"
    echo -e "前端面板地址: http://your-server-ip:3001"
    echo -e "后端API地址: http://your-server-ip:3000"
}

# 卸载面板
uninstall_panel() {
    check_root
    systemctl stop lemp-panel
    systemctl disable lemp-panel
    rm -f /etc/systemd/system/lemp-panel.service
    systemctl daemon-reload
    rm -rf "$INSTALL_DIR"
    rm -rf "$LOG_DIR"
    echo -e "${GREEN}卸载完成${NC}"
}

# 启动服务
start_service() {
    systemctl start lemp-panel
}

# 停止服务
stop_service() {
    systemctl stop lemp-panel
}

# 重启服务
restart_service() {
    systemctl restart lemp-panel
}

# 检查服务状态
check_status() {
    systemctl status lemp-panel
}

# 主函数
main() {
    case "$1" in
        install)
            install_panel
            ;;
        uninstall)
            uninstall_panel
            ;;
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            check_status
            ;;
        *)
            echo "用法: $0 {install|uninstall|start|stop|restart|status}"
            exit 1
            ;;
    esac
}

main "$@"
