'use client';

import React from 'react';
import { Box, Typography, Paper, CircularProgress } from '@mui/material';
import { useServiceMonitor } from '@/hooks/useServiceMonitor';
import type { ServiceStatus } from '@/types/monitoring';

export default function NginxMonitor() {
  const { status, loading, error } = useServiceMonitor('nginx');

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" p={3}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Paper sx={{ p: 3, bgcolor: '#ffebee' }}>
        <Typography color="error">
          错误：{error}
        </Typography>
      </Paper>
    );
  }

  const isActive = status?.isRunning ?? false;

  return (
    <Paper sx={{ p: 3, bgcolor: isActive ? '#e8f5e9' : '#ffebee' }}>
      <Typography variant="h5" gutterBottom>
        Nginx 状态
      </Typography>
      <Typography>
        当前状态：
        <Box component="span" sx={{ color: isActive ? 'success.main' : 'error.main', fontWeight: 'bold' }}>
          {isActive ? '运行中' : '已停止'}
        </Box>
      </Typography>
    </Paper>
  );
} 