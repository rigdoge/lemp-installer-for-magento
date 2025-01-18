'use client';

import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  TextField,
  Button,
  Switch,
  FormControlLabel,
  Paper,
  CircularProgress,
  Alert,
  Stack
} from '@mui/material';

export default function TelegramConfig() {
  const [isEnabled, setIsEnabled] = useState(false);
  const [botToken, setBotToken] = useState('');
  const [chatId, setChatId] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [debugInfo, setDebugInfo] = useState<any>(null);

  useEffect(() => {
    const fetchConfig = async () => {
      try {
        console.log('Fetching Telegram configuration...');
        const response = await fetch('/api/notifications/telegram');
        console.log('Response status:', response.status);
        
        if (!response.ok) {
          throw new Error('Failed to load configuration');
        }
        
        const data = await response.json();
        console.log('Configuration loaded:', data);
        
        setIsEnabled(data.enabled);
        setBotToken(data.botToken);
        setChatId(data.chatId);
        setDebugInfo(data._debug);
        setError(null);
      } catch (err) {
        console.error('Error loading configuration:', err);
        setError(err instanceof Error ? err.message : 'Failed to load configuration');
      } finally {
        setLoading(false);
      }
    };

    fetchConfig();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setSaving(true);

    try {
      console.log('Saving configuration...');
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
      
      console.log('Save response status:', response.status);
      const data = await response.json();
      console.log('Save response:', data);

      if (!response.ok) {
        throw new Error(data.error || 'Failed to save configuration');
      }

      setSuccess('配置已保存');
      setDebugInfo(data._debug);

      // 如果启用了通知，发送测试消息
      if (isEnabled) {
        console.log('Sending test message...');
        const testResponse = await fetch('/api/notifications/telegram', {
          method: 'PUT',
        });
        
        console.log('Test response status:', testResponse.status);
        const testData = await testResponse.json();
        console.log('Test response:', testData);

        if (!testResponse.ok) {
          throw new Error(testData.error || 'Failed to send test message');
        }

        setSuccess('配置已保存，测试消息已发送');
        setDebugInfo(testData._debug);
      }
    } catch (err) {
      console.error('Error saving configuration:', err);
      setError(err instanceof Error ? err.message : 'Failed to save configuration');
    } finally {
      setSaving(false);
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
    <Stack spacing={3}>
      <Typography variant="h5" gutterBottom>
        Telegram 通知配置 v2
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

      <form onSubmit={handleSubmit}>
        <Stack spacing={3}>
          <FormControlLabel
            control={
              <Switch
                checked={isEnabled}
                onChange={(e) => setIsEnabled(e.target.checked)}
                name="enabled"
              />
            }
            label="启用 Telegram 通知"
          />

          <TextField
            label="Bot Token"
            value={botToken}
            onChange={(e) => setBotToken(e.target.value)}
            required
            fullWidth
            error={!botToken}
            helperText={!botToken ? '请输入 Bot Token' : ''}
          />

          <TextField
            label="Chat ID"
            value={chatId}
            onChange={(e) => setChatId(e.target.value)}
            required
            fullWidth
            error={!chatId}
            helperText={!chatId ? '请输入 Chat ID' : ''}
          />

          <Button
            type="submit"
            variant="contained"
            disabled={saving || !botToken || !chatId}
          >
            {saving ? '保存中...' : '保存配置'}
          </Button>
        </Stack>
      </form>

      {debugInfo && (
        <Paper sx={{ p: 2, mt: 2, bgcolor: '#f5f5f5' }}>
          <Typography variant="subtitle2" gutterBottom>
            调试信息
          </Typography>
          <pre style={{ margin: 0, whiteSpace: 'pre-wrap' }}>
            {JSON.stringify(debugInfo, null, 2)}
          </pre>
        </Paper>
      )}
    </Stack>
  );
} 