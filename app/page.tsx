'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  FormControlLabel,
  Checkbox,
} from '@mui/material';
import { useAuth } from './contexts/AuthContext';

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await fetch('/api/auth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password, rememberMe }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || '登录失败');
      }

      await login(username, password);
      router.push('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : '登录失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      sx={{
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
      }}
    >
      <Card sx={{ width: 400, maxWidth: '90%' }}>
        <CardContent>
          <Typography variant="h5" align="center" gutterBottom>
            LEMP 管理面板
          </Typography>
          <form onSubmit={handleSubmit}>
            <TextField
              fullWidth
              label="用户名"
              margin="normal"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              disabled={loading}
            />
            <TextField
              fullWidth
              type="password"
              label="密码"
              margin="normal"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={loading}
            />
            <FormControlLabel
              control={
                <Checkbox
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  disabled={loading}
                />
              }
              label="记住登录状态"
            />
            {error && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {error}
              </Alert>
            )}
            <Button
              fullWidth
              variant="contained"
              type="submit"
              sx={{ mt: 3 }}
              disabled={loading}
            >
              {loading ? '登录中...' : '登录'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </Box>
  );
} 