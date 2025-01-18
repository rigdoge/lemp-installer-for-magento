import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// 获取当前配置
export async function GET() {
    try {
        console.log('Getting Telegram configuration...');
        const configPath = '/etc/monitoring/telegram.conf';
        const command = `sudo [ -f ${configPath} ] && sudo sh -c 'source ${configPath} && echo "{\\"enabled\\":\\"$ENABLED\\",\\"botToken\\":\\"$BOT_TOKEN\\",\\"chatId\\":\\"$CHAT_ID\\"}"' || echo "{\\"enabled\\":false,\\"botToken\\":\\"\\",\\"chatId\\":\\"\\"}"`;
        
        console.log('Executing command:', command);
        const { stdout, stderr } = await execAsync(command, { shell: '/bin/bash' });
        
        if (stderr) {
            console.error('Command stderr:', stderr);
        }
        
        console.log('Command output:', stdout);
        return NextResponse.json(JSON.parse(stdout));
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
        const { enabled, botToken, chatId } = await request.json();
        
        if (!botToken || !chatId) {
            console.error('Missing required fields:', { botToken: !!botToken, chatId: !!chatId });
            return NextResponse.json(
                { error: 'Bot token and chat ID are required' },
                { status: 400 }
            );
        }

        // 使用 monitor.sh 脚本更新配置
        const command = `sudo /home/doge/lemp-installer-for-magento/scripts/monitor.sh update-telegram "${botToken}" "${chatId}" "${enabled}"`;
        console.log('Executing command:', command);
        
        const { stdout, stderr } = await execAsync(command, { shell: '/bin/bash' });
        console.log('Command output:', stdout);
        if (stderr) {
            console.error('Command stderr:', stderr);
        }

        // 验证配置文件是否已创建
        const { stdout: checkConfig } = await execAsync('sudo test -f /etc/monitoring/telegram.conf && echo "exists"', { shell: '/bin/bash' });
        if (!checkConfig.includes('exists')) {
            throw new Error('Configuration file was not created');
        }

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
        
        // 检查 Nginx 状态
        const { stdout: nginxStatus } = await execAsync('sudo systemctl is-active nginx', { shell: '/bin/bash' });
        const message = `测试消息\n\nNginx 状态: ${nginxStatus.trim()}`;
        
        // 获取配置并发送消息
        const configPath = '/etc/monitoring/telegram.conf';
        const command = `sudo [ -f ${configPath} ] && sudo sh -c 'source ${configPath} && curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=${encodeURIComponent(message)}"'`;
        
        console.log('Executing command:', command);
        const { stdout, stderr } = await execAsync(command, { shell: '/bin/bash' });
        
        if (stderr) {
            console.error('Command stderr:', stderr);
        }
        
        console.log('Command output:', stdout);
        return NextResponse.json({ success: true, result: stdout });
    } catch (error) {
        console.error('Error sending test message:', error);
        return NextResponse.json(
            { error: error instanceof Error ? error.message : 'Failed to send test message' },
            { status: 500 }
        );
    }
} 