export interface TelegramConfig {
    enabled: boolean;
    botToken: string;
    chatId: string;
}

export interface NotificationMessage {
    title: string;
    message: string;
    type: 'info' | 'warning' | 'error';
} 