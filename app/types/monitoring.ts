export interface NginxStatus {
    isRunning: boolean;
    connections: {
        active: number;
        reading: number;
        writing: number;
        waiting: number;
    };
    requests: {
        total: number;
        perSecond: number;
    };
    workers: {
        total: number;
        busy: number;
    };
}

export interface ServiceStatus {
    isRunning: boolean;
    metrics?: Record<string, any>;
} 