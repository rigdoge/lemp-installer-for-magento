import { NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';
import type { MonitoringConfig } from '@/types/monitoring';

const CONFIG_FILE = path.join('/home/doge/lemp-installer-for-magento/config', 'monitoring.json');

// 默认配置
const DEFAULT_CONFIG: MonitoringConfig = {
    enabled: true,
    levels: {
        basic: true,       // 默认开启基础监控
        performance: false, // 默认关闭性能监控
        security: false,    // 默认关闭安全监控
    },
    intervals: {
        basic: 60,        // 1分钟
        performance: 300,  // 5分钟
        security: 3600,    // 1小时
    },
    notifications: {
        status: true,      // 默认开启状态通知
        performance: false, // 默认关闭性能通知
        security: true,    // 默认开启安全通知
    },
    thresholds: {
        connections: 1000,  // 1000个连接
        errorRate: 5,      // 5%错误率
        responseTime: 500,  // 500ms响应时间
    },
};

// 确保配置目录存在
async function ensureConfigFile() {
    try {
        await fs.access(CONFIG_FILE);
    } catch (error) {
        const configDir = path.dirname(CONFIG_FILE);
        await fs.mkdir(configDir, { recursive: true });
        await fs.writeFile(CONFIG_FILE, JSON.stringify(DEFAULT_CONFIG, null, 2));
    }
}

// 获取配置
export async function GET() {
    try {
        await ensureConfigFile();
        const data = await fs.readFile(CONFIG_FILE, 'utf8');
        const config = JSON.parse(data);
        return NextResponse.json(config);
    } catch (error) {
        console.error('Error reading monitoring config:', error);
        return NextResponse.json(
            { error: 'Failed to read monitoring configuration' },
            { status: 500 }
        );
    }
}

// 更新配置
export async function POST(request: Request) {
    try {
        const newConfig = await request.json();
        
        // 验证必要的字段
        if (!newConfig.levels || !newConfig.intervals || !newConfig.notifications || !newConfig.thresholds) {
            return NextResponse.json(
                { error: 'Invalid configuration format' },
                { status: 400 }
            );
        }

        // 合并配置，保留默认值
        const config = {
            ...DEFAULT_CONFIG,
            ...newConfig,
            levels: { ...DEFAULT_CONFIG.levels, ...newConfig.levels },
            intervals: { ...DEFAULT_CONFIG.intervals, ...newConfig.intervals },
            notifications: { ...DEFAULT_CONFIG.notifications, ...newConfig.notifications },
            thresholds: { ...DEFAULT_CONFIG.thresholds, ...newConfig.thresholds },
        };

        await ensureConfigFile();
        await fs.writeFile(CONFIG_FILE, JSON.stringify(config, null, 2));

        return NextResponse.json({ success: true, config });
    } catch (error) {
        console.error('Error updating monitoring config:', error);
        return NextResponse.json(
            { error: 'Failed to update monitoring configuration' },
            { status: 500 }
        );
    }
} 