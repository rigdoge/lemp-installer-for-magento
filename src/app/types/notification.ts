export interface TelegramConfig {
    enabled: boolean;
    botToken: string;
    chatId: string;
}

export interface NotificationMessage {
    type: 'info' | 'warning' | 'error';
    title: string;
    message: string;
    timestamp: string;
} 