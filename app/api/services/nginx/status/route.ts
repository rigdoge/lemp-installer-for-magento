import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';
import { sendTelegramMessage } from '../../../../utils/telegram';

const execAsync = promisify(exec);
const STATUS_FILE = path.join('/home/doge/lemp-installer-for-magento/config', 'nginx_status.json');

// 读取上一次的状态
async function getLastStatus(): Promise<string | null> {
    try {
        const data = await fs.readFile(STATUS_FILE, 'utf8');
        const status = JSON.parse(data);
        return status.lastStatus;
    } catch (error) {
        return null;
    }
}

// 保存当前状态
async function saveStatus(status: string) {
    try {
        await fs.writeFile(STATUS_FILE, JSON.stringify({ lastStatus: status }));
    } catch (error) {
        console.error('Error saving status:', error);
    }
}

export async function GET() {
    let lastStatus: string | null = null;
    
    try {
        console.log('Checking Nginx status...');
        
        // 获取上一次的状态
        lastStatus = await getLastStatus();
        
        // 使用 systemctl 检查 Nginx 状态
        const { stdout } = await execAsync('systemctl is-active nginx', { shell: '/bin/bash' });
        const currentStatus = stdout.trim();
        
        console.log('Nginx status:', currentStatus);
        
        // 检查状态是否发生变化
        if (lastStatus !== null && lastStatus !== currentStatus) {
            // 发送状态变化通知
            const message = currentStatus === 'active'
                ? '✅ Nginx 已恢复运行'
                : '❌ Nginx 已停止运行';
            
            await sendTelegramMessage(message);
        }
        
        // 保存当前状态
        await saveStatus(currentStatus);
        
        return NextResponse.json({
            isRunning: currentStatus === 'active',
            metrics: {
                status: currentStatus,
                lastStatus
            }
        });
    } catch (error) {
        console.error('Error checking Nginx status:', error);
        
        // 如果是因为 Nginx 服务不存在而失败，也发送通知
        if (lastStatus === 'active') {
            await sendTelegramMessage('❌ Nginx 服务异常');
        }
        
        return NextResponse.json(
            { error: error instanceof Error ? error.message : 'Failed to check Nginx status' },
            { status: 500 }
        );
    }
} 