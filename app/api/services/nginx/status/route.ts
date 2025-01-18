import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';
import { sendTelegramMessage } from '../../../../utils/telegram';

const execAsync = promisify(exec);
const CONFIG_DIR = '/home/doge/lemp-installer-for-magento/config';
const STATUS_FILE = path.join(CONFIG_DIR, 'nginx_status.json');

// 读取上一次的状态
async function getLastStatus(): Promise<string | null> {
    try {
        await fs.mkdir(CONFIG_DIR, { recursive: true });
        try {
            const data = await fs.readFile(STATUS_FILE, 'utf8');
            const status = JSON.parse(data);
            return status.lastStatus;
        } catch (error) {
            // 如果文件不存在，返回 null
            if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
                return null;
            }
            throw error;
        }
    } catch (error) {
        console.error('Error reading last status:', error);
        return null;
    }
}

// 保存当前状态
async function saveStatus(status: string) {
    try {
        await fs.mkdir(CONFIG_DIR, { recursive: true });
        await fs.writeFile(STATUS_FILE, JSON.stringify({ 
            lastStatus: status,
            timestamp: new Date().toISOString()
        }));
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
        console.log('Last status:', lastStatus);
        
        // 使用 systemctl 检查 Nginx 状态
        const { stdout } = await execAsync('systemctl is-active nginx', { shell: '/bin/bash' });
        const currentStatus = stdout.trim();
        
        console.log('Current status:', currentStatus);
        
        // 检查状态是否发生变化
        if (lastStatus !== currentStatus) {
            // 发送状态变化通知
            if (currentStatus === 'active') {
                await sendTelegramMessage('✅ Nginx 已恢复运行');
            } else if (currentStatus === 'inactive' || currentStatus === 'failed') {
                await sendTelegramMessage('❌ Nginx 已停止运行');
            }
        }
        
        // 保存当前状态
        await saveStatus(currentStatus);
        
        return NextResponse.json({
            isRunning: currentStatus === 'active',
            metrics: {
                status: currentStatus,
                lastStatus,
                timestamp: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('Error checking Nginx status:', error);
        
        // 如果是因为 Nginx 服务不存在而失败，也发送通知
        if (lastStatus === 'active') {
            await sendTelegramMessage('❌ Nginx 服务异常');
            // 保存异常状态
            await saveStatus('failed');
        }
        
        return NextResponse.json(
            { 
                error: error instanceof Error ? error.message : 'Failed to check Nginx status',
                metrics: {
                    status: 'failed',
                    lastStatus,
                    timestamp: new Date().toISOString()
                }
            },
            { status: 500 }
        );
    }
} 