'use client';

import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Switch,
  FormControlLabel,
  TextField,
  Grid,
  Button,
  Alert,
  CircularProgress
} from '@mui/material';
import type { MonitoringConfig } from '../../types/monitoring';

export default function PrometheusConfig() {
  const [config, setConfig] = useState<MonitoringConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  useEffect(() => {
    fetchConfig();
  }, []);

  const fetchConfig = async () => {
    try {
      const response = await fetch('/api/monitoring/config');
      if (!response.ok) {
        throw new Error('Failed to fetch configuration');
      }
      const data = await response.json();
      setConfig(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!config) return;
    
    setSaving(true);
    try {
      const response = await fetch('/api/monitoring/config', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(config),
      });

      if (!response.ok) {
        throw new Error('Failed to save configuration');
      }

      setSuccess('Configuration saved successfully');
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      setSuccess(null);
    } finally {
      setSaving(false);
    }
  };

  const handleExporterToggle = (exporter: 'nginx' | 'mysql' | 'redis' | 'node') => {
    if (!config?.prometheus?.exporters) return;
    
    setConfig({
      ...config,
      prometheus: {
        ...config.prometheus,
        exporters: {
          ...config.prometheus.exporters,
          [exporter]: !config.prometheus.exporters[exporter],
        },
      },
    });
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" p={3}>
        <CircularProgress />
      </Box>
    );
  }

  if (!config) {
    return (
      <Alert severity="error">
        Failed to load configuration
      </Alert>
    );
  }

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h6" gutterBottom>
        Prometheus 监控配置
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Typography variant="subtitle1" gutterBottom>
            Prometheus 配置
          </Typography>
          <FormControlLabel
            control={
              <Switch
                checked={config.prometheus?.enabled ?? false}
                onChange={(e) => setConfig({
                  ...config,
                  prometheus: {
                    ...config.prometheus!,
                    enabled: e.target.checked,
                  },
                })}
              />
            }
            label="启用 Prometheus 监控"
          />
        </Grid>

        {config.prometheus?.enabled && (
          <>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Prometheus 端口"
                type="number"
                value={config.prometheus?.port ?? 9090}
                onChange={(e) => setConfig({
                  ...config,
                  prometheus: {
                    ...config.prometheus!,
                    port: parseInt(e.target.value),
                  },
                })}
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="数据保留时间"
                value={config.prometheus?.retention ?? "15d"}
                onChange={(e) => setConfig({
                  ...config,
                  prometheus: {
                    ...config.prometheus!,
                    retention: e.target.value,
                  },
                })}
                helperText="例如: 15d, 30d, 60d"
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="采集间隔"
                value={config.prometheus?.scrapeInterval ?? "15s"}
                onChange={(e) => setConfig({
                  ...config,
                  prometheus: {
                    ...config.prometheus!,
                    scrapeInterval: e.target.value,
                  },
                })}
                helperText="例如: 15s, 30s, 1m"
              />
            </Grid>

            <Grid item xs={12}>
              <Typography variant="subtitle1" gutterBottom sx={{ mt: 2 }}>
                Exporters 配置
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={6} md={3}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={config.prometheus?.exporters?.nginx ?? false}
                        onChange={() => handleExporterToggle('nginx')}
                      />
                    }
                    label="Nginx Exporter"
                  />
                </Grid>
                <Grid item xs={6} md={3}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={config.prometheus?.exporters?.mysql ?? false}
                        onChange={() => handleExporterToggle('mysql')}
                      />
                    }
                    label="MySQL Exporter"
                  />
                </Grid>
                <Grid item xs={6} md={3}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={config.prometheus?.exporters?.redis ?? false}
                        onChange={() => handleExporterToggle('redis')}
                      />
                    }
                    label="Redis Exporter"
                  />
                </Grid>
                <Grid item xs={6} md={3}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={config.prometheus?.exporters?.node ?? false}
                        onChange={() => handleExporterToggle('node')}
                      />
                    }
                    label="Node Exporter"
                  />
                </Grid>
              </Grid>
            </Grid>
          </>
        )}

        <Grid item xs={12} sx={{ mt: 3 }}>
          <Typography variant="subtitle1" gutterBottom>
            Alertmanager 配置
          </Typography>
          <FormControlLabel
            control={
              <Switch
                checked={config.alertmanager?.enabled ?? false}
                onChange={(e) => setConfig({
                  ...config,
                  alertmanager: {
                    ...config.alertmanager!,
                    enabled: e.target.checked,
                  },
                })}
              />
            }
            label="启用 Alertmanager 告警"
          />
        </Grid>

        {config.alertmanager?.enabled && (
          <>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Alertmanager 端口"
                type="number"
                value={config.alertmanager?.port ?? 9093}
                onChange={(e) => setConfig({
                  ...config,
                  alertmanager: {
                    ...config.alertmanager!,
                    port: parseInt(e.target.value),
                  },
                })}
              />
            </Grid>

            <Grid item xs={12}>
              <Typography variant="subtitle1" gutterBottom sx={{ mt: 2 }}>
                告警通知方式
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={6} md={3}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={config.alertmanager?.receivers?.telegram ?? false}
                        onChange={(e) => setConfig({
                          ...config,
                          alertmanager: {
                            ...config.alertmanager!,
                            receivers: {
                              ...config.alertmanager!.receivers,
                              telegram: e.target.checked,
                            },
                          },
                        })}
                      />
                    }
                    label="Telegram 通知"
                  />
                </Grid>
                <Grid item xs={6} md={3}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={config.alertmanager?.receivers?.email ?? false}
                        onChange={(e) => setConfig({
                          ...config,
                          alertmanager: {
                            ...config.alertmanager!,
                            receivers: {
                              ...config.alertmanager!.receivers,
                              email: e.target.checked,
                            },
                          },
                        })}
                      />
                    }
                    label="邮件通知"
                  />
                </Grid>
              </Grid>
            </Grid>

            <Grid item xs={12}>
              <Typography variant="body2" color="textSecondary" sx={{ mt: 2 }}>
                告警规则配置：
                <br />
                • 服务状态告警：当服务停止运行时触发
                <br />
                • 性能告警：当系统负载过高或响应时间异常时触发
                <br />
                • 错误率告警：当错误率超过阈值时触发
                <br />
                • 资源告警：当系统资源（CPU、内存、磁盘）使用率过高时触发
              </Typography>
            </Grid>
          </>
        )}

        <Grid item xs={12}>
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
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={saving}
          >
            {saving ? '保存中...' : '保存配置'}
          </Button>
        </Grid>
      </Grid>
    </Paper>
  );
} 