import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function GET() {
    try {
        // 检查 Nginx 状态
        const { stdout: statusOutput } = await execAsync('systemctl is-active nginx');
        const isRunning = statusOutput.trim() === 'active';

        if (!isRunning) {
            return NextResponse.json({
                isRunning: false,
                connections: { active: 0, reading: 0, writing: 0, waiting: 0 },
                requests: { total: 0, perSecond: 0 },
                workers: { total: 0, busy: 0, idle: 0 }
            });
        }

        // 获取 Nginx 统计信息
        const { stdout: statsOutput } = await execAsync('curl -s http://localhost/nginx_status');
        
        // 解析 nginx status 输出
        const stats = await parseNginxStats(statsOutput);

        return NextResponse.json({
            isRunning: true,
            ...stats
        });
    } catch (error) {
        console.error('Error fetching Nginx status:', error);
        return NextResponse.json(
            { error: 'Failed to fetch Nginx status' },
            { status: 500 }
        );
    }
}

async function parseNginxStats(output: string) {
    const lines = output.split('\n');
    const stats = {
        connections: {
            active: 0,
            reading: 0,
            writing: 0,
            waiting: 0
        },
        requests: {
            total: 0,
            perSecond: 0
        },
        workers: {
            total: 0,
            busy: 0,
            idle: 0
        }
    };

    try {
        // Active connections
        const activeConnections = lines[0].match(/Active connections: (\d+)/);
        if (activeConnections) {
            stats.connections.active = parseInt(activeConnections[1]);
        }

        // Server accepts handled requests
        const requestStats = lines[2].split(' ');
        if (requestStats.length >= 3) {
            stats.requests.total = parseInt(requestStats[2]);
            stats.requests.perSecond = stats.requests.total / 60; // 简化的计算
        }

        // Reading Writing Waiting
        const rwwStats = lines[3].match(/Reading: (\d+) Writing: (\d+) Waiting: (\d+)/);
        if (rwwStats) {
            stats.connections.reading = parseInt(rwwStats[1]);
            stats.connections.writing = parseInt(rwwStats[2]);
            stats.connections.waiting = parseInt(rwwStats[3]);
        }

        // 获取工作进程信息
        const { stdout: workersOutput } = await execAsync('ps aux | grep nginx | grep worker | wc -l');
        stats.workers.total = parseInt(workersOutput);
        stats.workers.busy = stats.connections.active;
        stats.workers.idle = stats.workers.total - stats.workers.busy;
    } catch (error) {
        console.error('Error parsing Nginx stats:', error);
    }

    return stats;
} 