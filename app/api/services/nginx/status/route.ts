import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';
import { sendTelegramMessage } from '../../../../utils/telegram';

const execAsync = promisify(exec);
const CONFIG_DIR = path.join(process.cwd(), 'config');
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
            // 如果文件不存在或解析失败，返回 null
            console.log('No previous status found or parse error:', error);
            return null;
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
        const data = JSON.stringify({ 
            lastStatus: status,
            timestamp: new Date().toISOString()
        }, null, 2);
        
        await fs.writeFile(STATUS_FILE, data, { encoding: 'utf8', mode: 0o666 });
        console.log('Status saved:', data);
    } catch (error) {
        console.error('Error saving status:', error);
        throw error;
    }
}

// 检查 Nginx 状态
async function checkNginxStatus(): Promise<string> {
    try {
        // 检测操作系统
        const { stdout: osType } = await execAsync('uname');
        const isLinux = osType.trim().toLowerCase() === 'linux';
        
        if (isLinux) {
            // Linux 使用 systemctl
            const { stdout } = await execAsync('systemctl is-active nginx');
            return stdout.trim();
        } else {
            // macOS 使用 ps 命令检查
            const { stdout } = await execAsync('ps aux | grep nginx | grep -v grep');
            return stdout.includes('nginx') ? 'active' : 'inactive';
        }
    } catch (error) {
        console.error('Error checking nginx status:', error);
        if (error instanceof Error) {
            console.error('Error details:', error.message);
        }
        return 'inactive';
    }
}

export async function GET() {
    let lastStatus: string | null = null;
    let currentStatus: string;
    
    try {
        console.log('Checking Nginx status...');
        
        // 获取上一次的状态
        lastStatus = await getLastStatus();
        console.log('Last status:', lastStatus);
        
        // 检查当前状态
        currentStatus = await checkNginxStatus();
        console.log('Current status:', currentStatus);
        
        // 检查状态是否发生变化
        const statusChanged = lastStatus !== null && lastStatus !== currentStatus;
        console.log('Status changed?', statusChanged);
        
        if (statusChanged) {
            console.log('Status changed from', lastStatus, 'to', currentStatus);
            
            // 发送状态变化通知
            if (currentStatus === 'active') {
                await sendTelegramMessage('✅ Nginx 已恢复运行');
            } else {
                await sendTelegramMessage('❌ Nginx 已停止运行');
            }
        }
        
        // 总是保存当前状态
        await saveStatus(currentStatus);
        
        return NextResponse.json({
            isRunning: currentStatus === 'active',
            metrics: {
                status: currentStatus,
                lastStatus,
                statusChanged,
                timestamp: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('Error in status check:', error);
        
        // 如果之前是运行状态，现在出错了，发送通知
        if (lastStatus === 'active') {
            await sendTelegramMessage('❌ Nginx 服务异常');
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