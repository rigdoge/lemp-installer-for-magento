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
  Radio,
  RadioGroup,
  Alert,
  CircularProgress,
} from '@mui/material';

interface DeploymentConfig {
  host: string;
  username: string;
  authType: 'password' | 'sshKey';
  password?: string;
  sshKey?: string;
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
    username: 'root',
    authType: 'password',
    password: '',
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
          body: JSON.stringify({
            host: config.host,
            authType: config.authType,
            password: config.password,
            sshKey: config.sshKey,
          }),
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
                    label="SSH 用户名"
                    value={config.username}
                    onChange={(e) => setConfig({...config, username: e.target.value})}
                    helperText="输入 SSH 登录用户名，默认为 root"
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControl component="fieldset">
                    <Typography variant="subtitle1" gutterBottom>
                      认证方式
                    </Typography>
                    <RadioGroup
                      value={config.authType}
                      onChange={(e) => setConfig({
                        ...config,
                        authType: e.target.value as 'password' | 'sshKey',
                        password: '',
                        sshKey: ''
                      })}
                    >
                      <FormControlLabel
                        value="password"
                        control={<Radio />}
                        label="密码登录"
                      />
                      <FormControlLabel
                        value="sshKey"
                        control={<Radio />}
                        label="SSH 密钥"
                      />
                    </RadioGroup>
                  </FormControl>
                </Grid>
                <Grid item xs={12}>
                  {config.authType === 'password' ? (
                    <TextField
                      fullWidth
                      type="password"
                      label="SSH 密码"
                      value={config.password || ''}
                      onChange={(e) => setConfig({...config, password: e.target.value})}
                      helperText="输入 SSH 登录密码"
                    />
                  ) : (
                    <TextField
                      fullWidth
                      label="SSH 密钥"
                      multiline
                      rows={4}
                      value={config.sshKey || ''}
                      onChange={(e) => setConfig({...config, sshKey: e.target.value})}
                      helperText="输入 SSH 私钥内容"
                    />
                  )}
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
                          <Radio
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
                  <Typography variant="subtitle1">认证方式: {config.authType === 'password' ? '密码登录' : 'SSH 密钥'}</Typography>
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
      
      <Stepper activeStep={activeStep} sx={{ mb: 4 }}>
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

      <Box sx={{ mt: 3, display: 'flex', justifyContent: 'flex-end' }}>
        {activeStep > 0 && (
          <Button
            onClick={handleBack}
            sx={{ mr: 1 }}
            disabled={loading}
          >
            上一步
          </Button>
        )}
        {activeStep < steps.length - 1 && (
          <Button
            variant="contained"
            onClick={handleNext}
            disabled={loading}
          >
            {activeStep === steps.length - 2 ? '开始安装' : '下一步'}
          </Button>
        )}
      </Box>
    </Box>
  );
} 