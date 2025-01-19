'use client';

import React, { useState } from 'react';
import { Grid, Paper, Typography, Box, CircularProgress, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField } from '@mui/material';
import { styled } from '@mui/material/styles';
import StorageIcon from '@mui/icons-material/Storage';
import MemoryIcon from '@mui/icons-material/Memory';
import SpeedIcon from '@mui/icons-material/Speed';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import useSWR, { mutate } from 'swr';

interface ServiceStatus {
  status: 'running' | 'stopped' | 'error';
}

interface MagentoStatus {
  mode: string;
  cacheStatus: {
    enabled: number;
    total: number;
  };
  orders: {
    today: number;
  };
  activeUsers: number;
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
  sites: {
    [key: string]: {
      name: string;
      path: string;
      status: MagentoStatus;
    };
  };
  services: {
    [key: string]: ServiceStatus;
  };
}

interface Site {
  id: string;
  name: string;
  path: string;
  enabled: boolean;
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
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [siteName, setSiteName] = useState('');
  const [sitePath, setSitePath] = useState('');
  const [editingSite, setEditingSite] = useState<Site | null>(null);

  const { data: systemData, error: systemError, isLoading: systemLoading } = 
    useSWR<SystemStatusData>('/api/system/status', fetcher, {
      refreshInterval: 5000
    });

  const { data: sites, error: sitesError, isLoading: sitesLoading } = 
    useSWR<Site[]>('/api/sites', fetcher);

  const handleAddSite = async () => {
    if (!siteName || !sitePath) return;

    const site = {
      id: editingSite?.id,
      name: siteName,
      path: sitePath,
      enabled: true
    };

    await fetch('/api/sites', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(site),
    });

    setSiteName('');
    setSitePath('');
    setEditingSite(null);
    setIsDialogOpen(false);
    mutate('/api/sites');
  };

  const handleDeleteSite = async (id: string) => {
    await fetch('/api/sites', {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ id }),
    });
    mutate('/api/sites');
  };

  const handleEditSite = (site: Site) => {
    setEditingSite(site);
    setSiteName(site.name);
    setSitePath(site.path);
    setIsDialogOpen(true);
  };

  if (systemError || sitesError) {
    return (
      <Box sx={{ p: 3, textAlign: 'center' }}>
        <Typography color="error">
          获取系统状态失败
        </Typography>
      </Box>
    );
  }

  if (systemLoading || sitesLoading || !systemData) {
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
                {systemData.uptime}
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
                {systemData.cpu.usage.toFixed(1)}%
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
                {systemData.memory.usage.toFixed(1)}% ({formatBytes(systemData.memory.used)}/{formatBytes(systemData.memory.total)})
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
                {systemData.disk.usage.toFixed(1)}% ({formatBytes(systemData.disk.used)}/{formatBytes(systemData.disk.total)})
              </Typography>
            </Box>
          </MetricBox>
        </Item>
      </Grid>

      {/* Magento 站点状态卡片 */}
      <Grid item xs={12} md={6}>
        <Item>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h6">
              Magento 站点
            </Typography>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={() => {
                setEditingSite(null);
                setSiteName('');
                setSitePath('');
                setIsDialogOpen(true);
              }}
            >
              添加站点
            </Button>
          </Box>
          {sites && sites.map((site) => (
            <Paper
              key={site.id}
              sx={{ p: 2, mb: 2, position: 'relative' }}
              variant="outlined"
            >
              <Box sx={{ position: 'absolute', top: 8, right: 8 }}>
                <Button
                  size="small"
                  onClick={() => handleEditSite(site)}
                  sx={{ mr: 1 }}
                >
                  编辑
                </Button>
                <Button
                  size="small"
                  color="error"
                  startIcon={<DeleteIcon />}
                  onClick={() => handleDeleteSite(site.id)}
                >
                  删除
                </Button>
              </Box>
              <Typography variant="subtitle1" gutterBottom>
                {site.name}
              </Typography>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                路径: {site.path}
              </Typography>
              {systemData.sites[site.id] ? (
                <>
                  <Box sx={{ mt: 2 }}>
                    <Typography variant="body2" color="text.secondary">
                      运行模式
                    </Typography>
                    <Typography variant="body1">
                      {systemData.sites[site.id].status.mode}
                    </Typography>
                  </Box>
                  <Box sx={{ mt: 1 }}>
                    <Typography variant="body2" color="text.secondary">
                      缓存状态
                    </Typography>
                    <Typography variant="body1">
                      已启用 ({systemData.sites[site.id].status.cacheStatus.enabled}/{systemData.sites[site.id].status.cacheStatus.total})
                    </Typography>
                  </Box>
                  <Box sx={{ mt: 1 }}>
                    <Typography variant="body2" color="text.secondary">
                      今日订单数
                    </Typography>
                    <Typography variant="body1">
                      {systemData.sites[site.id].status.orders.today}
                    </Typography>
                  </Box>
                  <Box sx={{ mt: 1 }}>
                    <Typography variant="body2" color="text.secondary">
                      当前活跃用户
                    </Typography>
                    <Typography variant="body1">
                      {systemData.sites[site.id].status.activeUsers}
                    </Typography>
                  </Box>
                </>
              ) : (
                <Typography color="error">
                  无法获取站点状态
                </Typography>
              )}
            </Paper>
          ))}
        </Item>
      </Grid>

      {/* 服务状态卡片 */}
      <Grid item xs={12}>
        <Item>
          <Typography variant="h6" gutterBottom>
            服务状态
          </Typography>
          <Grid container spacing={2}>
            {Object.entries(systemData.services).map(([service, status]) => (
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

      {/* 添加/编辑站点对话框 */}
      <Dialog open={isDialogOpen} onClose={() => setIsDialogOpen(false)}>
        <DialogTitle>
          {editingSite ? '编辑站点' : '添加新站点'}
        </DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="站点名称"
            fullWidth
            value={siteName}
            onChange={(e) => setSiteName(e.target.value)}
          />
          <TextField
            margin="dense"
            label="站点路径"
            fullWidth
            value={sitePath}
            onChange={(e) => setSitePath(e.target.value)}
            helperText="例如: /home/doge/html"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setIsDialogOpen(false)}>
            取消
          </Button>
          <Button onClick={handleAddSite} variant="contained">
            {editingSite ? '保存' : '添加'}
          </Button>
        </DialogActions>
      </Dialog>
    </Grid>
  );
} 