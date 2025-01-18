'use client';

import React, { useState, useEffect } from 'react';
import { 
    Card, 
    CardContent, 
    TextField, 
    Button, 
    Typography, 
    Box, 
    Switch,
    FormControlLabel,
    Alert,
    CircularProgress,
    Stack
} from '@mui/material';
import { TelegramConfig as TelegramConfigType } from '../../types/notification';

export const TelegramConfig: React.FC = () => {
    const [config, setConfig] = useState<TelegramConfigType>({
        enabled: false,
        botToken: '',
        chatId: ''
    });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [testing, setTesting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState(false);

    // 加载配置
    useEffect(() => {
        fetch('/api/notifications/telegram')
            .then(res => res.json())
            .then(data => {
                setConfig(data);
                setLoading(false);
            })
            .catch(err => {
                setError('Failed to load configuration');
                setLoading(false);
            });
    }, []);

    // 保存配置
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true);
        setError(null);
        setSuccess(false);

        try {
            const res = await fetch('/api/notifications/telegram', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(config),
            });

            if (!res.ok) {
                throw new Error('Failed to save configuration');
            }

            setSuccess(true);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Unknown error');
        } finally {
            setSaving(false);
        }
    };

    // 测试消息
    const handleTest = async () => {
        setTesting(true);
        setError(null);

        try {
            const res = await fetch('/api/notifications/telegram', {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!res.ok) {
                throw new Error('Failed to send test message');
            }

            setSuccess(true);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to send test message');
        } finally {
            setTesting(false);
        }
    };

    if (loading) {
        return (
            <Box display="flex" justifyContent="center" p={3}>
                <CircularProgress />
            </Box>
        );
    }

    return (
        <Card>
            <CardContent>
                <Typography variant="h6" gutterBottom>
                    Telegram 通知设置
                </Typography>

                {error && (
                    <Alert severity="error" sx={{ mb: 2 }}>
                        {error}
                    </Alert>
                )}

                {success && (
                    <Alert severity="success" sx={{ mb: 2 }}>
                        配置已保存成功
                    </Alert>
                )}

                <Box component="form" onSubmit={handleSubmit}>
                    <FormControlLabel
                        control={
                            <Switch
                                checked={config.enabled}
                                onChange={(e) => setConfig({ ...config, enabled: e.target.checked })}
                            />
                        }
                        label="启用 Telegram 通知"
                        sx={{ mb: 2 }}
                    />

                    <TextField
                        fullWidth
                        label="Bot Token"
                        value={config.botToken}
                        onChange={(e) => setConfig({ ...config, botToken: e.target.value })}
                        margin="normal"
                        required
                        disabled={!config.enabled}
                    />

                    <TextField
                        fullWidth
                        label="Chat ID"
                        value={config.chatId}
                        onChange={(e) => setConfig({ ...config, chatId: e.target.value })}
                        margin="normal"
                        required
                        disabled={!config.enabled}
                        helperText="您可以从 @userinfobot 获取您的 Chat ID"
                    />

                    <Stack direction="row" spacing={2} sx={{ mt: 2 }}>
                        <Button
                            type="submit"
                            variant="contained"
                            disabled={saving || !config.enabled}
                        >
                            {saving ? '保存中...' : '保存配置'}
                        </Button>
                        <Button
                            variant="outlined"
                            onClick={handleTest}
                            disabled={testing || !config.enabled || !success}
                        >
                            {testing ? '发送中...' : '发送测试消息'}
                        </Button>
                    </Stack>
                </Box>
            </CardContent>
        </Card>
    );
}; 