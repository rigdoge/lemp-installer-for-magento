'use client';

import { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  Chip,
  IconButton,
  Tooltip,
  Button,
  Link,
} from '@mui/material';
import {
  Notifications as NotificationsIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
  Info as InfoIcon,
  CheckCircle as CheckCircleIcon,
  OpenInNew as OpenInNewIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';

interface Alert {
  fingerprint: string;
  status: {
    state: 'active' | 'suppressed' | 'resolved';
    silencedBy?: string[];
    inhibitedBy?: string[];
  };
  labels: {
    alertname: string;
    severity: 'critical' | 'warning' | 'info';
    instance: string;
    job: string;
    [key: string]: string;
  };
  annotations: {
    description: string;
    summary: string;
    [key: string]: string;
  };
  startsAt: string;
  endsAt: string;
  updatedAt: string;
}

interface AlertmanagerStatus {
  running: boolean;
  error?: string;
}

export default function NotificationsPage() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [status, setStatus] = useState<AlertmanagerStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAlerts = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/notifications/alerts');
      if (!response.ok) {
        throw new Error('Failed to fetch alerts');
      }
      const data = await response.json();
      setAlerts(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const fetchStatus = async () => {
    try {
      const response = await fetch('/api/notifications/status');
      if (!response.ok) {
        throw new Error('Failed to fetch Alertmanager status');
      }
      const data = await response.json();
      setStatus(data);
    } catch (err) {
      console.error('Error fetching Alertmanager status:', err);
    }
  };

  useEffect(() => {
    fetchAlerts();
    fetchStatus();
    // 每30秒刷新一次
    const interval = setInterval(() => {
      fetchAlerts();
      fetchStatus();
    }, 30000);
    return () => clearInterval(interval);
  }, []);

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical':
        return <ErrorIcon color="error" />;
      case 'warning':
        return <WarningIcon color="warning" />;
      case 'info':
        return <InfoIcon color="info" />;
      default:
        return <NotificationsIcon />;
    }
  };

  const getStatusColor = (state: string) => {
    switch (state) {
      case 'active':
        return 'error';
      case 'suppressed':
        return 'warning';
      case 'resolved':
        return 'success';
      default:
        return 'default';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('zh-CN');
  };

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">通知中心</Typography>
        <Box>
          <Tooltip title="刷新">
            <IconButton onClick={() => { fetchAlerts(); fetchStatus(); }}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          {status?.running && (
            <Button
              variant="outlined"
              endIcon={<OpenInNewIcon />}
              component={Link}
              href={process.env.NEXT_PUBLIC_ALERTMANAGER_URL || 'http://localhost:9093'}
              target="_blank"
              sx={{ ml: 1 }}
            >
              打开 Alertmanager
            </Button>
          )}
        </Box>
      </Box>

      {status && (
        <Paper sx={{ p: 2, mb: 3 }}>
          <Grid container alignItems="center" spacing={2}>
            <Grid item>
              {status.running ? (
                <CheckCircleIcon color="success" />
              ) : (
                <ErrorIcon color="error" />
              )}
            </Grid>
            <Grid item xs>
              <Typography>
                Alertmanager 状态: {status.running ? '运行中' : '未运行'}
              </Typography>
              {status.error && (
                <Typography color="error" variant="body2">
                  错误: {status.error}
                </Typography>
              )}
            </Grid>
          </Grid>
        </Paper>
      )}

      {error ? (
        <Typography color="error" sx={{ mb: 2 }}>
          {error}
        </Typography>
      ) : (
        <Grid container spacing={3}>
          {alerts.map((alert) => (
            <Grid item xs={12} key={alert.fingerprint}>
              <Card>
                <CardContent>
                  <Box display="flex" alignItems="center" mb={1}>
                    {getSeverityIcon(alert.labels.severity)}
                    <Typography variant="h6" sx={{ ml: 1, flexGrow: 1 }}>
                      {alert.labels.alertname}
                    </Typography>
                    <Chip
                      label={alert.status.state}
                      color={getStatusColor(alert.status.state)}
                      size="small"
                    />
                  </Box>
                  <Typography color="text.secondary" gutterBottom>
                    {alert.annotations.description || alert.annotations.summary}
                  </Typography>
                  <Box mt={2}>
                    <Typography variant="body2" color="text.secondary">
                      实例: {alert.labels.instance}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      开始时间: {formatDate(alert.startsAt)}
                    </Typography>
                    {alert.status.state === 'resolved' && (
                      <Typography variant="body2" color="text.secondary">
                        结束时间: {formatDate(alert.endsAt)}
                      </Typography>
                    )}
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))}
          {alerts.length === 0 && !loading && (
            <Grid item xs={12}>
              <Paper sx={{ p: 3, textAlign: 'center' }}>
                <CheckCircleIcon color="success" sx={{ fontSize: 48, mb: 2 }} />
                <Typography>目前没有任何告警</Typography>
              </Paper>
            </Grid>
          )}
        </Grid>
      )}
    </Box>
  );
} 