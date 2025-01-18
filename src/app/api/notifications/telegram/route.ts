import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// 获取当前配置
export async function GET() {
    try {
        const configPath = '/etc/monitoring/telegram.conf';
        const { stdout } = await execAsync(`[ -f ${configPath} ] && source ${configPath} && echo "{\\"botToken\\":\\"$BOT_TOKEN\\",\\"chatId\\":\\"$CHAT_ID\\"}" || echo "{}"`);
        return NextResponse.json(JSON.parse(stdout));
    } catch (error) {
        return NextResponse.json({ error: 'Failed to get Telegram configuration' }, { status: 500 });
    }
}

// 更新配置
export async function POST(request: Request) {
    try {
        const { botToken, chatId } = await request.json();
        
        if (!botToken || !chatId) {
            return NextResponse.json(
                { error: 'Bot token and chat ID are required' },
                { status: 400 }
            );
        }

        // 使用 monitor.sh 脚本更新配置
        await execAsync(`sudo /opt/lemp-manager/scripts/monitor.sh update-telegram "${botToken}" "${chatId}"`);

        return NextResponse.json({ success: true });
    } catch (error) {
        return NextResponse.json(
            { error: 'Failed to update Telegram configuration' },
            { status: 500 }
        );
    }
} 