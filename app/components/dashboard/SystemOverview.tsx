'use client';

import React from 'react';
import { Grid, Paper, Typography, Box, CircularProgress } from '@mui/material';
import { styled } from '@mui/material/styles';
import StorageIcon from '@mui/icons-material/Storage';
import MemoryIcon from '@mui/icons-material/Memory';
import SpeedIcon from '@mui/icons-material/Speed';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import useSWR from 'swr';

interface ServiceStatus {
  status: 'running' | 'stopped' | 'error';
}

interface SystemStatusData {
  uptime: string;
  cpu: {
    usage: number;
  };
  memory: {
    usage: number;
    used: number;
    total: number;
  };
  disk: {
    usage: number;
    used: number;
    total: number;
  };
  magento: {
    mode: string;
    cacheStatus: {
      enabled: number;
      total: number;
    };
    orders: {
      today: number;
    };
    activeUsers: number;
  };
  services: {
    [key: string]: ServiceStatus;
  };
}

const Item = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(2),
  color: theme.palette.text.primary,
}));

const MetricBox = styled(Box)(({ theme }) => ({
  display: 'flex',
  alignItems: 'center',
  marginBottom: theme.spacing(2),
  '& > svg': {
    marginRight: theme.spacing(2),
    fontSize: '2rem',
  },
}));

const fetcher = (url: string) => fetch(url).then(res => res.json());

const formatBytes = (bytes: number) => {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
};

export default function SystemOverview() {
  const { data, error, isLoading } = useSWR<SystemStatusData>('/api/system/status', fetcher, {
    refreshInterval: 5000 // 每5秒刷新一次
  });

  if (error) {
    return (
      <Box sx={{ p: 3, textAlign: 'center' }}>
        <Typography color="error">
          获取系统状态失败
        </Typography>
      </Box>
    );
  }

  if (isLoading || !data) {
    return (
      <Box sx={{ p: 3, textAlign: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Grid container spacing={3}>
      {/* 系统状态卡片 */}
      <Grid item xs={12} md={6}>
        <Item>
          <Typography variant="h6" gutterBottom>
            系统状态
          </Typography>
          <MetricBox>
            <AccessTimeIcon />
            <Box>
              <Typography variant="body2" color="text.secondary">
                系统运行时间
              </Typography>
              <Typography variant="h6">
                {data.uptime}
              </Typography>
            </Box>
          </MetricBox>
          <MetricBox>
            <SpeedIcon />
            <Box>
              <Typography variant="body2" color="text.secondary">
                CPU 使用率
              </Typography>
              <Typography variant="h6">
                {data.cpu.usage.toFixed(1)}%
              </Typography>
            </Box>
          </MetricBox>
          <MetricBox>
            <MemoryIcon />
            <Box>
              <Typography variant="body2" color="text.secondary">
                内存使用率
              </Typography>
              <Typography variant="h6">
                {data.memory.usage.toFixed(1)}% ({formatBytes(data.memory.used)}/{formatBytes(data.memory.total)})
              </Typography>
            </Box>
          </MetricBox>
          <MetricBox>
            <StorageIcon />
            <Box>
              <Typography variant="body2" color="text.secondary">
                磁盘使用率
              </Typography>
              <Typography variant="h6">
                {data.disk.usage.toFixed(1)}% ({formatBytes(data.disk.used)}/{formatBytes(data.disk.total)})
              </Typography>
            </Box>
          </MetricBox>
        </Item>
      </Grid>

      {/* Magento 状态卡片 */}
      <Grid item xs={12} md={6}>
        <Item>
          <Typography variant="h6" gutterBottom>
            Magento 状态
          </Typography>
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" color="text.secondary">
              运行模式
            </Typography>
            <Typography variant="h6">
              {data.magento.mode}
            </Typography>
          </Box>
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" color="text.secondary">
              缓存状态
            </Typography>
            <Typography variant="h6">
              已启用 ({data.magento.cacheStatus.enabled}/{data.magento.cacheStatus.total})
            </Typography>
          </Box>
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" color="text.secondary">
              今日订单数
            </Typography>
            <Typography variant="h6">
              {data.magento.orders.today}
            </Typography>
          </Box>
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" color="text.secondary">
              当前活跃用户
            </Typography>
            <Typography variant="h6">
              {data.magento.activeUsers}
            </Typography>
          </Box>
        </Item>
      </Grid>

      {/* 服务状态卡片 */}
      <Grid item xs={12}>
        <Item>
          <Typography variant="h6" gutterBottom>
            服务状态
          </Typography>
          <Grid container spacing={2}>
            {Object.entries(data.services).map(([service, status]) => (
              <Grid item xs={6} sm={3} key={service}>
                <Box sx={{ 
                  p: 2, 
                  borderRadius: 1,
                  bgcolor: status.status === 'running' ? 'success.main' : 
                          status.status === 'stopped' ? 'warning.main' : 'error.main',
                  color: 'white',
                  textAlign: 'center'
                }}>
                  <Typography variant="body1">
                    {service}
                  </Typography>
                  <Typography variant="body2">
                    {status.status === 'running' ? '运行中' : 
                     status.status === 'stopped' ? '已停止' : '错误'}
                  </Typography>
                </Box>
              </Grid>
            ))}
          </Grid>
        </Item>
      </Grid>
    </Grid>
  );
} 