'use client';

import React, { useState } from 'react';
import { Grid, Paper, Typography, Box, CircularProgress, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Alert, IconButton, Tooltip } from '@mui/material';
import { styled } from '@mui/material/styles';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import StorageIcon from '@mui/icons-material/Storage';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import PeopleIcon from '@mui/icons-material/People';
import CachedIcon from '@mui/icons-material/Cached';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import SettingsIcon from '@mui/icons-material/Settings';
import useSWR, { mutate } from 'swr';

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
  sites: {
    [key: string]: {
      name: string;
      path: string;
      status: MagentoStatus;
    };
  };
}

interface Site {
  id: string;
  name: string;
  path: string;
  enabled: boolean;
  frontendUrl?: string;
  adminUrl?: string;
}

const Item = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(3),
  color: theme.palette.mode === 'light' ? theme.palette.text.primary : theme.palette.text.primary,
  height: '100%',
  backgroundColor: theme.palette.mode === 'light' ? theme.palette.background.paper : theme.palette.background.paper,
}));

const MetricBox = styled(Box)(({ theme }) => ({
  display: 'flex',
  alignItems: 'center',
  marginBottom: theme.spacing(2),
  '& > svg': {
    marginRight: theme.spacing(2),
    fontSize: '2rem',
    color: theme.palette.primary.main,
  },
  '& .MuiTypography-root': {
    color: theme.palette.mode === 'light' ? theme.palette.text.primary : theme.palette.text.primary,
  },
  '& .MuiTypography-body2': {
    color: theme.palette.mode === 'light' ? theme.palette.text.secondary : theme.palette.text.secondary,
  },
}));

const fetcher = (url: string) => fetch(url).then(res => res.json());

export default function SiteMonitor() {
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [siteName, setSiteName] = useState('');
  const [sitePath, setSitePath] = useState('');
  const [editingSite, setEditingSite] = useState<Site | null>(null);
  const [frontendUrl, setFrontendUrl] = useState('');
  const [adminUrl, setAdminUrl] = useState('');

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
      enabled: true,
      frontendUrl: frontendUrl,
      adminUrl: adminUrl
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
    setFrontendUrl('');
    setAdminUrl('');
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
    setFrontendUrl(site.frontendUrl || '');
    setAdminUrl(site.adminUrl || '');
    setIsDialogOpen(true);
  };

  if (systemError || sitesError) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">
          获取站点状态失败
        </Alert>
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
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5" component="h1">
          Magento 站点监控
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            setEditingSite(null);
            setSiteName('');
            setSitePath('');
            setFrontendUrl('');
            setAdminUrl('');
            setIsDialogOpen(true);
          }}
        >
          添加站点
        </Button>
      </Box>

      <Grid container spacing={3}>
        {sites && sites.map((site) => (
          <Grid item xs={12} md={6} lg={4} key={site.id}>
            <Item>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
                <Box>
                  <Typography variant="h6" gutterBottom>
                    {site.name}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    路径: {site.path}
                  </Typography>
                  <Box sx={{ mt: 1, display: 'flex', gap: 1 }}>
                    {site.frontendUrl && (
                      <Tooltip title="访问前台">
                        <IconButton
                          size="small"
                          color="primary"
                          component="a"
                          href={site.frontendUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          <OpenInNewIcon />
                        </IconButton>
                      </Tooltip>
                    )}
                    {site.adminUrl && (
                      <Tooltip title="访问后台">
                        <IconButton
                          size="small"
                          color="primary"
                          component="a"
                          href={site.adminUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          <SettingsIcon />
                        </IconButton>
                      </Tooltip>
                    )}
                  </Box>
                </Box>
                <Box>
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
              </Box>

              {systemData.sites[site.id] ? (
                <>
                  <MetricBox>
                    <StorageIcon />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        运行模式
                      </Typography>
                      <Typography variant="h6">
                        {systemData.sites[site.id].status.mode}
                      </Typography>
                    </Box>
                  </MetricBox>

                  <MetricBox>
                    <CachedIcon />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        缓存状态
                      </Typography>
                      <Typography variant="h6">
                        已启用 ({systemData.sites[site.id].status.cacheStatus.enabled}/{systemData.sites[site.id].status.cacheStatus.total})
                      </Typography>
                    </Box>
                  </MetricBox>

                  <MetricBox>
                    <ShoppingCartIcon />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        今日订单数
                      </Typography>
                      <Typography variant="h6">
                        {systemData.sites[site.id].status.orders.today}
                      </Typography>
                    </Box>
                  </MetricBox>

                  <MetricBox>
                    <PeopleIcon />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        当前活跃用户
                      </Typography>
                      <Typography variant="h6">
                        {systemData.sites[site.id].status.activeUsers}
                      </Typography>
                    </Box>
                  </MetricBox>
                </>
              ) : (
                <Alert severity="error" sx={{ mt: 2 }}>
                  无法获取站点状态
                </Alert>
              )}
            </Item>
          </Grid>
        ))}
      </Grid>

      {/* 添加/编辑站点对话框 */}
      <Dialog 
        open={isDialogOpen} 
        onClose={() => setIsDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
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
          <TextField
            margin="dense"
            label="前台 URL"
            fullWidth
            value={frontendUrl}
            onChange={(e) => setFrontendUrl(e.target.value)}
            helperText="例如: https://magento.example.com"
          />
          <TextField
            margin="dense"
            label="后台 URL"
            fullWidth
            value={adminUrl}
            onChange={(e) => setAdminUrl(e.target.value)}
            helperText="例如: https://magento.example.com/admin"
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
    </Box>
  );
} 