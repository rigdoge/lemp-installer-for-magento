import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// 获取当前配置
export async function GET() {
    try {
        const configPath = '/etc/monitoring/telegram.conf';
        const { stdout } = await execAsync(`sudo [ -f ${configPath} ] && sudo sh -c 'source ${configPath} && echo "{\\"enabled\\":\\"$ENABLED\\",\\"botToken\\":\\"$BOT_TOKEN\\",\\"chatId\\":\\"$CHAT_ID\\"}"' || echo "{\\"enabled\\":false,\\"botToken\\":\\"\\",\\"chatId\\":\\"\\"}"`, { shell: '/bin/bash' });
        return NextResponse.json(JSON.parse(stdout));
    } catch (error) {
        console.error('Error getting Telegram configuration:', error);
        return NextResponse.json({ error: 'Failed to get Telegram configuration' }, { status: 500 });
    }
}

// 更新配置
export async function POST(request: Request) {
    try {
        const { enabled, botToken, chatId } = await request.json();
        
        if (!botToken || !chatId) {
            return NextResponse.json(
                { error: 'Bot token and chat ID are required' },
                { status: 400 }
            );
        }

        // 使用 monitor.sh 脚本更新配置
        const command = `sudo /opt/lemp-manager/scripts/monitor.sh update-telegram "${botToken}" "${chatId}" "${enabled}"`;
        console.log('Executing command:', command);
        
        const { stdout, stderr } = await execAsync(command, { shell: '/bin/bash' });
        console.log('Command output:', stdout);
        if (stderr) console.error('Command stderr:', stderr);

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
        const { stdout: nginxStatus } = await execAsync('sudo systemctl is-active nginx', { shell: '/bin/bash' });
        const message = `测试消息\n\nNginx 状态: ${nginxStatus.trim()}`;
        
        // 获取配置
        const configPath = '/etc/monitoring/telegram.conf';
        const { stdout: config } = await execAsync(`sudo [ -f ${configPath} ] && sudo sh -c 'source ${configPath} && curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=${encodeURIComponent(message)}"'`, { shell: '/bin/bash' });
        
        return NextResponse.json({ success: true, result: config });
    } catch (error) {
        console.error('Error sending test message:', error);
        return NextResponse.json(
            { error: 'Failed to send test message' },
            { status: 500 }
        );
    }
} 