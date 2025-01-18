import fs from 'fs/promises';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);
const CONFIG_DIR = process.env.CONFIG_DIR || '/home/doge/lemp-installer-for-magento/config';
const CONFIG_FILE = path.join(CONFIG_DIR, 'telegram.json');

interface TelegramConfig {
    enabled: boolean;
    botToken: string;
    chatId: string;
}

export async function sendTelegramMessage(message: string) {
    try {
        // 读取配置
        const configData = await fs.readFile(CONFIG_FILE, 'utf8');
        const config: TelegramConfig = JSON.parse(configData);

        if (!config.enabled || !config.botToken || !config.chatId) {
            console.log('Telegram notification is disabled or not configured');
            return;
        }

        // 发送消息
        const { stdout } = await execAsync(
            `curl -s -X POST "https://api.telegram.org/bot${config.botToken}/sendMessage" -d "chat_id=${config.chatId}&text=${encodeURIComponent(message)}"`,
            { shell: '/bin/bash' }
        );

        console.log('Telegram notification sent:', stdout);
        return true;
    } catch (error) {
        console.error('Failed to send Telegram notification:', error);
        return false;
    }
} 