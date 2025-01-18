'use client';

import React, { useState, useEffect } from 'react';
import { Box, Paper, Typography, Button, Grid, Alert, CircularProgress } from '@mui/material';

interface ServiceStatus {
  running: boolean;
  error?: string;
}

interface MonitoringStatus {
  prometheus?: ServiceStatus;
  alertmanager?: ServiceStatus;
  grafana?: ServiceStatus;
}

export default function PrometheusMonitor() {
  const [status, setStatus] = useState<MonitoringStatus>({});
  const [loading, setLoading] = useState(true);

  const checkServiceStatus = async () => {
    try {
      const response = await fetch('/api/monitoring/status');
      if (!response.ok) {
        throw new Error('Failed to fetch monitoring status');
      }
      const data = await response.json();
      setStatus(data);
    } catch (error) {
      console.error('Error checking service status:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    checkServiceStatus();
    const interval = setInterval(checkServiceStatus, 10000); // 每10秒检查一次
    return () => clearInterval(interval);
  }, []);

  const prometheusUrl = process.env.NEXT_PUBLIC_PROMETHEUS_URL || 'http://localhost:9090';
  const grafanaUrl = process.env.NEXT_PUBLIC_GRAFANA_URL || 'http://localhost:3000';
  const alertmanagerUrl = process.env.NEXT_PUBLIC_ALERTMANAGER_URL || 'http://localhost:9093';

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" p={3}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h6" gutterBottom>
        系统监控
      </Typography>
      
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Typography variant="subtitle1" gutterBottom>
            监控服务状态
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={4}>
              <Alert 
                severity={status.prometheus?.running ? "success" : "error"}
                sx={{ mb: 1 }}
              >
                Prometheus: {status.prometheus?.running ? "运行中" : "未运行"}
                {status.prometheus?.error && (
                  <Typography variant="caption" display="block">
                    {status.prometheus.error}
                  </Typography>
                )}
              </Alert>
            </Grid>
            <Grid item xs={12} md={4}>
              <Alert 
                severity={status.alertmanager?.running ? "success" : "error"}
                sx={{ mb: 1 }}
              >
                Alertmanager: {status.alertmanager?.running ? "运行中" : "未运行"}
                {status.alertmanager?.error && (
                  <Typography variant="caption" display="block">
                    {status.alertmanager.error}
                  </Typography>
                )}
              </Alert>
            </Grid>
            <Grid item xs={12} md={4}>
              <Alert 
                severity={status.grafana?.running ? "success" : "error"}
                sx={{ mb: 1 }}
              >
                Grafana: {status.grafana?.running ? "运行中" : "未运行"}
                {status.grafana?.error && (
                  <Typography variant="caption" display="block">
                    {status.grafana.error}
                  </Typography>
                )}
              </Alert>
            </Grid>
          </Grid>
        </Grid>

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
              disabled={!status.prometheus?.running}
            >
              打开 Prometheus
            </Button>
            <Button
              variant="contained"
              href={alertmanagerUrl}
              target="_blank"
              sx={{ mr: 2 }}
              disabled={!status.alertmanager?.running}
            >
              打开 Alertmanager
            </Button>
            <Button
              variant="contained"
              href={grafanaUrl}
              target="_blank"
              color="secondary"
              disabled={!status.grafana?.running}
            >
              打开 Grafana
            </Button>
          </Box>
          {(!status.prometheus?.running || !status.alertmanager?.running || !status.grafana?.running) && (
            <Alert severity="info" sx={{ mt: 2 }}>
              提示：部分服务未运行，请先在"监控配置"中启用相应的服务，或检查服务是否正确安装和启动。
            </Alert>
          )}
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