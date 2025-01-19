'use client';

import React from 'react';
import { Grid, Paper, Typography, Box } from '@mui/material';
import { styled } from '@mui/material/styles';
import StorageIcon from '@mui/icons-material/Storage';
import MemoryIcon from '@mui/icons-material/Memory';
import SpeedIcon from '@mui/icons-material/Speed';
import AccessTimeIcon from '@mui/icons-material/AccessTime';

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

export default function SystemOverview() {
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
                14天 3小时 22分钟
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
                32%
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
                45% (7.2GB/16GB)
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
                68% (137GB/200GB)
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
              Production
            </Typography>
          </Box>
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" color="text.secondary">
              缓存状态
            </Typography>
            <Typography variant="h6">
              已启用 (12/12)
            </Typography>
          </Box>
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" color="text.secondary">
              今日订单数
            </Typography>
            <Typography variant="h6">
              24
            </Typography>
          </Box>
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" color="text.secondary">
              当前活跃用户
            </Typography>
            <Typography variant="h6">
              156
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
            {[
              'Nginx', 'PHP-FPM', 'MySQL', 'Redis',
              'RabbitMQ', 'Varnish', 'OpenSearch', 'Memcached'
            ].map((service) => (
              <Grid item xs={6} sm={3} key={service}>
                <Box sx={{ 
                  p: 2, 
                  borderRadius: 1,
                  bgcolor: 'success.main',
                  color: 'white',
                  textAlign: 'center'
                }}>
                  <Typography variant="body1">
                    {service}
                  </Typography>
                  <Typography variant="body2">
                    运行中
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