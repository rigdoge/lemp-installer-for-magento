'use client';

import { useEffect, useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  CircularProgress,
  Button,
  Link,
} from '@mui/material';
import {
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  OpenInNew as OpenInNewIcon,
} from '@mui/icons-material';

interface ServiceStatus {
  running: boolean;
  error?: string;
}

interface MonitoringStatus {
  prometheus: ServiceStatus;
  alertmanager: ServiceStatus;
  grafana: ServiceStatus;
}

export default function MonitoringPage() {
  const [status, setStatus] = useState<MonitoringStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStatus = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/monitoring/status');
      if (!response.ok) {
        throw new Error('Failed to fetch monitoring status');
      }
      const data = await response.json();
      setStatus(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStatus();
    // 每30秒刷新一次状态
    const interval = setInterval(fetchStatus, 30000);
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="50vh">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box p={3}>
        <Typography color="error">{error}</Typography>
        <Button variant="contained" onClick={fetchStatus} sx={{ mt: 2 }}>
          重试
        </Button>
      </Box>
    );
  }

  const services = [
    {
      name: 'Prometheus',
      status: status?.prometheus,
      description: '指标收集和监控系统',
      url: process.env.NEXT_PUBLIC_PROMETHEUS_URL || 'http://localhost:9090',
    },
    {
      name: 'Alertmanager',
      status: status?.alertmanager,
      description: '告警管理系统',
      url: process.env.NEXT_PUBLIC_ALERTMANAGER_URL || 'http://localhost:9093',
    },
    {
      name: 'Grafana',
      status: status?.grafana,
      description: '数据可视化和仪表板',
      url: process.env.NEXT_PUBLIC_GRAFANA_URL || 'http://localhost:3000',
    },
  ];

  return (
    <Box p={3}>
      <Typography variant="h4" gutterBottom>
        系统监控
      </Typography>
      <Grid container spacing={3}>
        {services.map((service) => (
          <Grid item xs={12} md={4} key={service.name}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center" mb={2}>
                  <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                    {service.name}
                  </Typography>
                  {service.status?.running ? (
                    <CheckCircleIcon color="success" />
                  ) : (
                    <ErrorIcon color="error" />
                  )}
                </Box>
                <Typography color="text.secondary" gutterBottom>
                  {service.description}
                </Typography>
                {service.status?.error && (
                  <Typography color="error" variant="body2">
                    错误: {service.status.error}
                  </Typography>
                )}
                <Button
                  variant="outlined"
                  endIcon={<OpenInNewIcon />}
                  component={Link}
                  href={service.url}
                  target="_blank"
                  sx={{ mt: 2 }}
                  disabled={!service.status?.running}
                >
                  打开 {service.name}
                </Button>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
} 