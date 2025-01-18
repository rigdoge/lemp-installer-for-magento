'use client';

import React from 'react';
import { Box, Paper, Typography, Button, Grid } from '@mui/material';

export default function PrometheusMonitor() {
  const prometheusUrl = process.env.NEXT_PUBLIC_PROMETHEUS_URL || 'http://localhost:9090';
  const grafanaUrl = process.env.NEXT_PUBLIC_GRAFANA_URL || 'http://localhost:3000';

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h6" gutterBottom>
        系统监控
      </Typography>
      
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Typography variant="subtitle1" gutterBottom>
            监控工具
          </Typography>
          <Box sx={{ mb: 2 }}>
            <Button
              variant="contained"
              href={prometheusUrl}
              target="_blank"
              sx={{ mr: 2 }}
            >
              打开 Prometheus
            </Button>
            <Button
              variant="contained"
              href={grafanaUrl}
              target="_blank"
              color="secondary"
            >
              打开 Grafana
            </Button>
          </Box>
        </Grid>

        <Grid item xs={12}>
          <Typography variant="subtitle1" gutterBottom>
            监控指标
          </Typography>
          <Typography>
            • Nginx 指标 (端口 9113)
            <br />
            - 连接数统计
            <br />
            - 请求处理速率
            <br />
            - HTTP 状态码分布
            <br />
            - 响应时间统计
          </Typography>
        </Grid>

        <Grid item xs={12}>
          <Typography variant="subtitle1" gutterBottom>
            Grafana 仪表盘
          </Typography>
          <Typography>
            • Nginx 概览
            <br />
            - 实时连接数图表
            <br />
            - QPS 趋势图
            <br />
            - 错误率监控
            <br />
            - 性能指标展示
          </Typography>
        </Grid>
      </Grid>
    </Paper>
  );
} 