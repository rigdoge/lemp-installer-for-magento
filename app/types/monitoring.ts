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
    metrics?: {
        status: string;
        [key: string]: any;
    };
}

export interface ServiceError {
    error: string;
    details?: any;
} 