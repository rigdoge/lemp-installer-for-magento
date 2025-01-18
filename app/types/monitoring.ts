export interface NginxStatus {
    isRunning: boolean;
    connections?: {
        active: number;
        reading: number;
        writing: number;
        waiting: number;
    };
    requests?: {
        total: number;
        perSecond: number;
    };
    workers?: {
        total: number;
        busy: number;
    };
}

export interface ServiceStatus {
    isRunning: boolean;
    metrics?: {
        status: string;
        [key: string]: any;
    };
}

export interface ServiceError {
    error: string;
    details?: any;
}

export interface MonitoringConfig {
    enabled: boolean;
    levels: {
        basic: boolean;      // 基础状态监控（1分钟）
        performance: boolean; // 性能监控（5分钟）
        security: boolean;    // 安全监控（1小时）
    };
    intervals: {
        basic: number;      // 基础监控间隔（秒）
        performance: number; // 性能监控间隔（秒）
        security: number;    // 安全监控间隔（秒）
    };
    notifications: {
        status: boolean;     // 状态变化通知
        performance: boolean; // 性能告警通知
        security: boolean;    // 安全事件通知
    };
    thresholds: {
        connections: number;   // 最大连接数告警阈值
        errorRate: number;    // 错误率告警阈值（百分比）
        responseTime: number; // 响应时间告警阈值（毫秒）
    };
    prometheus?: {
        enabled: boolean;    // 是否启用 Prometheus
        port: number;       // Prometheus 服务端口
        retention: string;  // 数据保留时间
        scrapeInterval: string; // 采集间隔
        exporters: {
            nginx: boolean;  // Nginx Exporter
            mysql: boolean;  // MySQL Exporter
            redis: boolean;  // Redis Exporter
            node: boolean;   // Node Exporter
        };
    };
    alertmanager?: {
        enabled: boolean;   // 是否启用 Alertmanager
        port: number;      // Alertmanager 服务端口
        receivers: {
            telegram: boolean; // Telegram 通知
            email: boolean;    // 邮件通知
        };
    };
} 