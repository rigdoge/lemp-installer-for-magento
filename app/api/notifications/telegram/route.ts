import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

const CONFIG_FILE = path.join(process.env.CONFIG_DIR || '/etc/lemp-manager', 'telegram.json');

// 确保配置目录存在
function ensureConfigDir() {
  const configDir = path.dirname(CONFIG_FILE);
  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
  }
}

// 读取配置
function readConfig() {
  try {
    if (!fs.existsSync(CONFIG_FILE)) {
      return {
        enabled: false,
        botToken: '',
        chatId: ''
      };
    }
    const data = fs.readFileSync(CONFIG_FILE, 'utf8');
    return JSON.parse(data);
  } catch (err) {
    console.error('Error reading config:', err);
    return {
      enabled: false,
      botToken: '',
      chatId: ''
    };
  }
}

// 保存配置
function saveConfig(config: any) {
  try {
    ensureConfigDir();
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
    return true;
  } catch (err) {
    console.error('Error saving config:', err);
    return false;
  }
}

// 发送测试消息
async function sendTestMessage(config: any) {
  if (!config.enabled || !config.botToken || !config.chatId) {
    throw new Error('Telegram configuration is not complete');
  }

  const message = 'This is a test message from LEMP Stack Manager';
  const url = `https://api.telegram.org/bot${config.botToken}/sendMessage`;
  
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      chat_id: config.chatId,
      text: message,
    }),
  });

  if (!response.ok) {
    throw new Error('Failed to send test message');
  }

  return true;
}

// GET /api/notifications/telegram/config
export async function GET() {
  const config = readConfig();
  return NextResponse.json(config);
}

// POST /api/notifications/telegram/config
export async function POST(request: Request) {
  const config = await request.json();
  
  if (!saveConfig(config)) {
    return NextResponse.json(
      { error: 'Failed to save configuration' },
      { status: 500 }
    );
  }

  return NextResponse.json({ success: true });
}

// POST /api/notifications/telegram/test
export async function PUT(request: Request) {
  const config = readConfig();
  
  try {
    await sendTestMessage(config);
    return NextResponse.json({ success: true });
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Unknown error' },
      { status: 500 }
    );
  }
}