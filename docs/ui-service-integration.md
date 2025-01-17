# UI 与服务集成设计

## 1. 整体架构

```plaintext
[前端 UI] <-> [API 服务] <-> [服务管理器] <-> [系统服务]
   React        Express      Shell Scripts     Nginx等

+-------------+     +--------------+     +---------------+     +-----------+
|   前端 UI    | --> |   API 服务    | --> | 服务管理脚本   | --> | 系统服务   |
|  (React)    | <-- |  (Express)   | <-- | (Shell/Node)  | <-- | (Nginx等) |
+-------------+     +--------------+     +---------------+     +-----------+
```

## 2. 前端实现 (React)

### 2.1 服务控制面板组件
```typescript
// ServiceControlPanel.tsx
interface ServiceControls {
  name: string;          // 服务名称
  status: string;        // 当前状态
  version: string;       // 当前版本
  availableVersions: string[]; // 可用版本
}

const ServiceControlPanel: React.FC<ServiceControls> = () => {
  // 服务操作函数
  const handleInstall = async () => {
    const response = await api.post('/services/nginx/install');
    updateStatus(response.data);
  };
  
  const handleStart = async () => {
    const response = await api.post('/services/nginx/start');
    updateStatus(response.data);
  };
  
  // 其他操作函数...
  
  return (
    <div className="service-panel">
      <StatusIndicator status={status} />
      <VersionSelector versions={availableVersions} />
      <ActionButtons onInstall={handleInstall} onStart={handleStart} />
      <LogViewer serviceId={name} />
    </div>
  );
};
```

### 2.2 实时状态更新
```typescript
// StatusMonitor.ts
const useServiceStatus = (serviceName: string) => {
  const [status, setStatus] = useState<ServiceStatus>();
  
  useEffect(() => {
    // WebSocket 连接获取实时状态
    const ws = new WebSocket(`ws://api/services/${serviceName}/status`);
    
    ws.onmessage = (event) => {
      setStatus(JSON.parse(event.data));
    };
    
    return () => ws.close();
  }, [serviceName]);
  
  return status;
};
```

## 3. API 服务实现 (Express)

### 3.1 路由定义
```javascript
// routes/services.js
const express = require('express');
const router = express.Router();
const ServiceManager = require('../services/ServiceManager');

// 服务安装
router.post('/:service/install', async (req, res) => {
  const { service } = req.params;
  const { version } = req.body;
  
  try {
    const result = await ServiceManager.install(service, version);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 服务启动
router.post('/:service/start', async (req, res) => {
  const { service } = req.params;
  
  try {
    const result = await ServiceManager.start(service);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 其他路由...
```

### 3.2 服务管理器
```javascript
// services/ServiceManager.js
class ServiceManager {
  static async install(service, version) {
    // 调用对应服务的安装脚本
    const result = await this.executeCommand(
      service,
      'install',
      { version }
    );
    return result;
  }
  
  static async start(service) {
    // 调用服务启动脚本
    const result = await this.executeCommand(
      service,
      'start'
    );
    return result;
  }
  
  static async executeCommand(service, action, params = {}) {
    // 执行系统命令
    const command = this.buildCommand(service, action, params);
    return await exec(command);
  }
}
```

## 4. 服务管理脚本

### 4.1 Nginx 服务管理脚本
```bash
#!/bin/bash
# nginx-service.sh

# 安装函数
install_nginx() {
  local version=$1
  
  # 检查版本
  if ! check_version "$version"; then
    echo "Invalid version: $version"
    exit 1
  }
  
  # 安装过程
  apt-get update
  apt-get install -y nginx=$version
  
  # 返回状态
  echo '{"status": "success", "version": "'$version'"}'
}

# 启动函数
start_nginx() {
  systemctl start nginx
  
  # 检查启动状态
  if systemctl is-active nginx >/dev/null 2>&1; then
    echo '{"status": "running"}'
  else
    echo '{"status": "error", "message": "Failed to start nginx"}'
    exit 1
  fi
}

# 主函数
main() {
  local action=$1
  shift
  
  case $action in
    install)
      install_nginx "$@"
      ;;
    start)
      start_nginx
      ;;
    # 其他操作...
  esac
}

main "$@"
```

## 5. 状态监控实现

### 5.1 WebSocket 服务
```javascript
// StatusMonitor.js
const WebSocket = require('ws');
const ServiceManager = require('./ServiceManager');

class StatusMonitor {
  constructor(server) {
    this.wss = new WebSocket.Server({ server });
    this.clients = new Map();
    
    this.wss.on('connection', this.handleConnection.bind(this));
  }
  
  handleConnection(ws, req) {
    const serviceName = this.parseServiceName(req.url);
    this.clients.set(ws, serviceName);
    
    // 开始监控
    this.startMonitoring(ws, serviceName);
    
    ws.on('close', () => {
      this.clients.delete(ws);
    });
  }
  
  async startMonitoring(ws, serviceName) {
    while (this.clients.has(ws)) {
      const status = await ServiceManager.getStatus(serviceName);
      ws.send(JSON.stringify(status));
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
}
```

## 6. 安全考虑

### 6.1 权限控制
- API 认证和授权
- 操作审计日志
- 敏感操作确认

### 6.2 操作限制
- 并发操作控制
- 操作超时处理
- 错误重试机制

## 7. 错误处理

### 7.1 前端错误处理
```typescript
const handleServiceOperation = async (operation: string) => {
  try {
    setLoading(true);
    const result = await api.post(`/services/${serviceName}/${operation}`);
    showSuccess(`${operation} successful`);
  } catch (error) {
    showError(`${operation} failed: ${error.message}`);
  } finally {
    setLoading(false);
  }
};
```

### 7.2 后端错误处理
```javascript
const executeServiceOperation = async (req, res) => {
  try {
    // 验证请求
    validateRequest(req);
    
    // 检查服务状态
    await checkServiceStatus(req.params.service);
    
    // 执行操作
    const result = await performOperation(req);
    
    // 返回结果
    res.json(result);
  } catch (error) {
    // 错误分类和处理
    handleOperationError(error, res);
  }
};
```

## 8. 日志记录

### 8.1 操作日志
```javascript
const logServiceOperation = (service, operation, params) => {
  logger.info({
    timestamp: new Date(),
    service,
    operation,
    params,
    user: getCurrentUser(),
    status: 'started'
  });
};
```

### 8.2 状态变更日志
```javascript
const logStatusChange = (service, fromStatus, toStatus) => {
  logger.info({
    timestamp: new Date(),
    service,
    type: 'status_change',
    from: fromStatus,
    to: toStatus
  });
};
``` 