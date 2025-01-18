import React, { useState, useEffect } from 'react';
import {
  Box,
  Switch,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
} from '@mui/material';

export default function TelegramConfig() {
  const [isEnabled, setIsEnabled] = useState(false);
  const [botToken, setBotToken] = useState('');
  const [chatId, setChatId] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isTesting, setIsTesting] = useState(false);

  useEffect(() => {
    fetchConfig();
  }, []);

  const fetchConfig = async () => {
    try {
      setIsLoading(true);
      const response = await fetch('/api/notifications/telegram');
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.error || '获取配置失败');
      }

      setIsEnabled(data.enabled === 'true');
      setBotToken(data.botToken || '');
      setChatId(data.chatId || '');
    } catch (error) {
      console.error('Fetch error:', error);
      setError(`获取配置失败：${error instanceof Error ? error.message : '未知错误'}`);
    } finally {
      setIsLoading(false);
    }
  };

  const handleTest = async () => {
    try {
      setIsTesting(true);
      setError('');
      setSuccess('');

      const response = await fetch('/api/notifications/telegram', {
        method: 'PUT',
      });

      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.error || '测试消息发送失败');
      }

      setSuccess('测试消息已发送');
    } catch (error) {
      console.error('Test error:', error);
      setError(`测试失败：${error instanceof Error ? error.message : '未知错误'}`);
    } finally {
      setIsTesting(false);
    }
  };

  const handleSave = async () => {
    try {
      setIsSaving(true);
      setError('');
      setSuccess('');

      const response = await fetch('/api/notifications/telegram', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          enabled: isEnabled,
          botToken,
          chatId,
        }),
      });

      const data = await response.json();
      
      if (!response.ok) {
        console.error('Save failed:', data);
        throw new Error(data.error || `HTTP error! status: ${response.status}`);
      }

      if (data.success) {
        setSuccess('配置已保存');
        if (isEnabled) {
          handleTest();
        }
      } else {
        throw new Error('保存失败：服务器返回未知错误');
      }
    } catch (error) {
      console.error('Save error:', error);
      setError(`保存失败：${error instanceof Error ? error.message : '未知错误'}`);
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" p={3}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Telegram 通知设置 <Typography component="span" color="primary" sx={{ fontSize: '0.8em' }}>[v1]</Typography>
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {success}
        </Alert>
      )}

      <Box mb={3}>
        <Switch
          checked={isEnabled}
          onChange={(e) => setIsEnabled(e.target.checked)}
          color="primary"
        />
        <Typography component="span" ml={1}>
          启用 Telegram 通知
        </Typography>
      </Box>

      <Box mb={3}>
        <TextField
          fullWidth
          label="Bot Token *"
          value={botToken}
          onChange={(e) => setBotToken(e.target.value)}
          margin="normal"
          required
          error={!botToken}
          helperText={!botToken ? '请输入 Bot Token' : ''}
        />
      </Box>

      <Box mb={3}>
        <TextField
          fullWidth
          label="Chat ID *"
          value={chatId}
          onChange={(e) => setChatId(e.target.value)}
          margin="normal"
          required
          error={!chatId}
          helperText={!chatId ? '请输入 Chat ID' : '您可以从 @userinfobot 获取您的 Chat ID'}
        />
      </Box>

      <Box display="flex" gap={2}>
        <Button
          variant="contained"
          onClick={handleSave}
          disabled={isSaving || !botToken || !chatId}
        >
          {isSaving ? <CircularProgress size={24} /> : '保存配置'}
        </Button>

        <Button
          variant="outlined"
          onClick={handleTest}
          disabled={isTesting || !isEnabled || !botToken || !chatId}
        >
          {isTesting ? <CircularProgress size={24} /> : '发送测试消息'}
        </Button>
      </Box>
    </Box>
  );
} 