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
        // 确保配置目录存在
        await fs.mkdir(CONFIG_DIR, { recursive: true });

        // 读取配置
        let configData: string;
        try {
            configData = await fs.readFile(CONFIG_FILE, 'utf8');
        } catch (error) {
            console.error('Failed to read Telegram config:', error);
            if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
                console.log('Telegram config file not found');
            }
            return false;
        }

        // 解析配置
        let config: TelegramConfig;
        try {
            config = JSON.parse(configData);
        } catch (error) {
            console.error('Failed to parse Telegram config:', error);
            return false;
        }

        if (!config.enabled) {
            console.log('Telegram notification is disabled');
            return false;
        }

        if (!config.botToken || !config.chatId) {
            console.error('Telegram config is incomplete');
            return false;
        }

        // 发送消息
        const command = `curl -s -X POST "https://api.telegram.org/bot${config.botToken}/sendMessage" -d "chat_id=${config.chatId}&text=${encodeURIComponent(message)}"`;
        console.log('Sending Telegram message...');
        
        const { stdout, stderr } = await execAsync(command, { shell: '/bin/bash' });
        
        if (stderr) {
            console.error('Telegram API stderr:', stderr);
        }

        const response = JSON.parse(stdout);
        if (!response.ok) {
            console.error('Telegram API error:', response);
            return false;
        }

        console.log('Telegram notification sent successfully');
        return true;
    } catch (error) {
        console.error('Failed to send Telegram notification:', error);
        if (error instanceof Error) {
            console.error('Error details:', error.message);
        }
        return false;
    }
} 