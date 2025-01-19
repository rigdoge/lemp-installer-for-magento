'use client';

import { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Stepper,
  Step,
  StepLabel,
  Button,
  Grid,
  Card,
  CardContent,
  TextField,
  FormControl,
  FormControlLabel,
  Checkbox,
  Alert,
  CircularProgress,
} from '@mui/material';

interface DeploymentConfig {
  host: string;
  sshKey: string;
  components: {
    nginx: boolean;
    php: boolean;
    mysql: boolean;
    redis: boolean;
    varnish: boolean;
    opensearch: boolean;
    rabbitmq: boolean;
  };
  versions: {
    nginx: string;
    php: string;
    mysql: string;
    redis: string;
    varnish: string;
    opensearch: string;
    rabbitmq: string;
  };
}

const steps = ['环境检查', '配置选择', '部署确认', '安装进度'];

export default function DeploymentPage() {
  const [activeStep, setActiveStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [checkResults, setCheckResults] = useState<any>(null);
  const [config, setConfig] = useState<DeploymentConfig>({
    host: '',
    sshKey: '',
    components: {
      nginx: true,
      php: true,
      mysql: true,
      redis: true,
      varnish: true,
      opensearch: true,
      rabbitmq: true,
    },
    versions: {
      nginx: '1.24',
      php: '8.2',
      mysql: '8.0',
      redis: '7.2',
      varnish: '7.5',
      opensearch: '2.12',
      rabbitmq: '3.13',
    },
  });

  const handleNext = async () => {
    setError(null);
    setLoading(true);

    try {
      if (activeStep === 0) {
        // 执行环境检查
        const response = await fetch('/api/deployment/check', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ host: config.host, sshKey: config.sshKey }),
        });
        
        if (!response.ok) throw new Error('环境检查失败');
        const results = await response.json();
        setCheckResults(results);
      }
      else if (activeStep === 2) {
        // 开始部署
        const response = await fetch('/api/deployment/install', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(config),
        });
        
        if (!response.ok) throw new Error('部署失败');
      }
      
      setActiveStep((prev) => prev + 1);
    } catch (err) {
      setError(err instanceof Error ? err.message : '操作失败');
    } finally {
      setLoading(false);
    }
  };

  const handleBack = () => {
    setActiveStep((prev) => prev - 1);
  };

  const renderStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                环境配置
              </Typography>
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="目标主机"
                    value={config.host}
                    onChange={(e) => setConfig({...config, host: e.target.value})}
                    helperText="输入目标服务器的 IP 地址或域名"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="SSH 密钥"
                    multiline
                    rows={4}
                    value={config.sshKey}
                    onChange={(e) => setConfig({...config, sshKey: e.target.value})}
                    helperText="输入 SSH 私钥内容"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        );

      case 1:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                组件选择
              </Typography>
              <Grid container spacing={3}>
                {Object.entries(config.components).map(([key, value]) => (
                  <Grid item xs={12} sm={6} key={key}>
                    <FormControl fullWidth>
                      <FormControlLabel
                        control={
                          <Checkbox
                            checked={value}
                            onChange={(e) => setConfig({
                              ...config,
                              components: {
                                ...config.components,
                                [key]: e.target.checked
                              }
                            })}
                          />
                        }
                        label={key.toUpperCase()}
                      />
                      {value && (
                        <TextField
                          size="small"
                          label="版本"
                          value={config.versions[key as keyof typeof config.versions]}
                          onChange={(e) => setConfig({
                            ...config,
                            versions: {
                              ...config.versions,
                              [key]: e.target.value
                            }
                          })}
                        />
                      )}
                    </FormControl>
                  </Grid>
                ))}
              </Grid>
            </CardContent>
          </Card>
        );

      case 2:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                确认配置
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <Typography variant="subtitle1">目标主机: {config.host}</Typography>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="subtitle1">选择的组件:</Typography>
                  {Object.entries(config.components)
                    .filter(([, value]) => value)
                    .map(([key]) => (
                      <Typography key={key} variant="body2">
                        • {key.toUpperCase()}: v{config.versions[key as keyof typeof config.versions]}
                      </Typography>
                    ))}
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        );

      case 3:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                安装进度
              </Typography>
              {/* 这里可以添加实时安装日志显示 */}
              <Box sx={{ mt: 2 }}>
                <CircularProgress />
              </Box>
            </CardContent>
          </Card>
        );

      default:
        return null;
    }
  };

  return (
    <Box p={3}>
      <Typography variant="h4" gutterBottom>
        部署管理
      </Typography>
      
      <Paper sx={{ p: 3, mb: 3 }}>
        <Stepper activeStep={activeStep} sx={{ mb: 3 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {renderStepContent(activeStep)}

        <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 3 }}>
          {activeStep !== 0 && (
            <Button
              onClick={handleBack}
              sx={{ mr: 1 }}
              disabled={loading}
            >
              上一步
            </Button>
          )}
          {activeStep !== steps.length - 1 && (
            <Button
              variant="contained"
              onClick={handleNext}
              disabled={loading}
            >
              {activeStep === steps.length - 2 ? '开始部署' : '下一步'}
            </Button>
          )}
        </Box>
      </Paper>
    </Box>
  );
} 