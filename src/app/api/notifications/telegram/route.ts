import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';

const execAsync = promisify(exec);

// 配置文件路径
const CONFIG_FILE = path.join('/home/doge/lemp-installer-for-magento/config', 'telegram.json');

// 确保配置目录存在
async function ensureConfigDir() {
    const configDir = path.dirname(CONFIG_FILE);
    try {
        console.log('Creating config directory:', configDir);
        await fs.mkdir(configDir, { recursive: true });
        console.log('Config directory created or already exists');
        
        // 检查目录权限
        const stats = await fs.stat(configDir);
        console.log('Config directory permissions:', {
            mode: stats.mode.toString(8),
            uid: stats.uid,
            gid: stats.gid
        });
    } catch (error) {
        console.error('Error creating config directory:', error);
        throw error;
    }
}

// 获取当前配置
export async function GET() {
    try {
        console.log('Getting Telegram configuration...');
        console.log('Config file path:', CONFIG_FILE);
        console.log('Current working directory:', process.cwd());
        
        await ensureConfigDir();
        
        try {
            const configData = await fs.readFile(CONFIG_FILE, 'utf8');
            console.log('Config loaded:', configData);
            return NextResponse.json(JSON.parse(configData));
        } catch (error: any) {
            console.log('Error reading config:', error);
            if (error?.code === 'ENOENT') {
                console.log('Config file does not exist, returning default config');
                // 如果文件不存在，返回默认配置
                return NextResponse.json({
                    enabled: false,
                    botToken: '',
                    chatId: ''
                });
            }
            throw error;
        }
    } catch (error) {
        console.error('Error getting Telegram configuration:', error);
        return NextResponse.json(
            { error: error instanceof Error ? error.message : 'Failed to get Telegram configuration' },
            { status: 500 }
        );
    }
}

// 更新配置
export async function POST(request: Request) {
    try {
        console.log('Updating Telegram configuration...');
        console.log('Config file path:', CONFIG_FILE);
        
        const { enabled, botToken, chatId } = await request.json();
        console.log('Received config:', { enabled, botToken: '***', chatId });
        
        if (!botToken || !chatId) {
            console.error('Missing required fields:', { botToken: !!botToken, chatId: !!chatId });
            return NextResponse.json(
                { error: 'Bot token and chat ID are required' },
                { status: 400 }
            );
        }

        await ensureConfigDir();
        
        // 保存配置到文件
        const config = { enabled, botToken, chatId };
        await fs.writeFile(CONFIG_FILE, JSON.stringify(config, null, 2));
        console.log('Config saved successfully');

        // 验证配置是否已保存
        const savedConfig = await fs.readFile(CONFIG_FILE, 'utf8');
        console.log('Verified saved config:', savedConfig);

        return NextResponse.json({ success: true });
    } catch (error) {
        console.error('Error updating Telegram configuration:', error);
        return NextResponse.json(
            { error: error instanceof Error ? error.message : 'Failed to update Telegram configuration' },
            { status: 500 }
        );
    }
}

// 测试 Telegram 通知
export async function PUT(request: Request) {
    try {
        console.log('Testing Telegram notification...');
        console.log('Config file path:', CONFIG_FILE);
        
        // 读取配置
        const configData = await fs.readFile(CONFIG_FILE, 'utf8');
        console.log('Config loaded for testing:', configData);
        const config = JSON.parse(configData);
        
        if (!config.enabled || !config.botToken || !config.chatId) {
            throw new Error('Telegram is not properly configured');
        }

        // 检查 Nginx 状态
        const { stdout: nginxStatus } = await execAsync('systemctl is-active nginx', { shell: '/bin/bash' });
        const message = `测试消息\n\nNginx 状态: ${nginxStatus.trim()}`;
        
        // 发送消息
        const { stdout } = await execAsync(
            `curl -s -X POST "https://api.telegram.org/bot${config.botToken}/sendMessage" -d "chat_id=${config.chatId}&text=${encodeURIComponent(message)}"`,
            { shell: '/bin/bash' }
        );
        
        console.log('Test message sent:', stdout);
        return NextResponse.json({ success: true, result: stdout });
    } catch (error) {
        console.error('Error sending test message:', error);
        return NextResponse.json(
            { error: error instanceof Error ? error.message : 'Failed to send test message' },
            { status: 500 }
        );
    }
} 