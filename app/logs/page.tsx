'use client';

import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Tabs,
  Tab,
  TextField,
  IconButton,
  Chip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Button,
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import RefreshIcon from '@mui/icons-material/Refresh';
import DownloadIcon from '@mui/icons-material/Download';
import DeleteIcon from '@mui/icons-material/Delete';
import { DataGrid } from '@mui/x-data-grid';

const logTypes = [
  { id: 'nginx-access', name: 'Nginx 访问日志' },
  { id: 'nginx-error', name: 'Nginx 错误日志' },
  { id: 'php-fpm', name: 'PHP-FPM 日志' },
  { id: 'mysql-error', name: 'MySQL 错误日志' },
  { id: 'magento-system', name: 'Magento 系统日志' },
  { id: 'magento-exception', name: 'Magento 异常日志' },
  { id: 'redis', name: 'Redis 日志' },
  { id: 'varnish', name: 'Varnish 日志' },
  { id: 'rabbitmq', name: 'RabbitMQ 日志' },
  { id: 'opensearch', name: 'OpenSearch 日志' },
  { id: 'system', name: 'System 日志' }
];

const logLevels = ['ERROR', 'WARNING', 'INFO', 'DEBUG'];

const columns = [
  { field: 'timestamp', headerName: '时间', width: 200 },
  { field: 'level', headerName: '级别', width: 100,
    renderCell: (params: any) => (
      <Chip 
        label={params.value} 
        color={
          params.value === 'ERROR' ? 'error' :
          params.value === 'WARNING' ? 'warning' :
          params.value === 'INFO' ? 'info' : 'default'
        }
        size="small"
      />
    )
  },
  { field: 'source', headerName: '来源', width: 150 },
  { field: 'message', headerName: '消息', flex: 1 }
];

// 示例数据，实际应该从 OpenSearch 获取
const sampleData = [
  { id: 1, timestamp: '2024-01-19 12:00:00', level: 'ERROR', source: 'nginx-error', message: '404 Not Found: /api/unknown' },
  { id: 2, timestamp: '2024-01-19 12:01:00', level: 'INFO', source: 'php-fpm', message: 'Pool www started' },
  { id: 3, timestamp: '2024-01-19 12:02:00', level: 'WARNING', source: 'mysql-error', message: 'Slow query detected' }
];

export default function LogsPage() {
  const [selectedLogType, setSelectedLogType] = useState('');
  const [selectedLevel, setSelectedLevel] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [timeRange, setTimeRange] = useState('1h');
  const [tabValue, setTabValue] = useState(0);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" gutterBottom>
        日志管理
      </Typography>

      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={tabValue}
          onChange={handleTabChange}
          variant="scrollable"
          scrollButtons="auto"
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab label="实时日志" />
          <Tab label="历史日志" />
          <Tab label="日志分析" />
          <Tab label="告警设置" />
        </Tabs>
      </Paper>

      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={3}>
          <FormControl fullWidth>
            <InputLabel>日志类型</InputLabel>
            <Select
              value={selectedLogType}
              label="日志类型"
              onChange={(e) => setSelectedLogType(e.target.value)}
            >
              <MenuItem value="">全部</MenuItem>
              {logTypes.map(type => (
                <MenuItem key={type.id} value={type.id}>{type.name}</MenuItem>
              ))}
            </Select>
          </FormControl>
        </Grid>
        <Grid item xs={12} md={2}>
          <FormControl fullWidth>
            <InputLabel>日志级别</InputLabel>
            <Select
              value={selectedLevel}
              label="日志级别"
              onChange={(e) => setSelectedLevel(e.target.value)}
            >
              <MenuItem value="">全部</MenuItem>
              {logLevels.map(level => (
                <MenuItem key={level} value={level}>{level}</MenuItem>
              ))}
            </Select>
          </FormControl>
        </Grid>
        <Grid item xs={12} md={2}>
          <FormControl fullWidth>
            <InputLabel>时间范围</InputLabel>
            <Select
              value={timeRange}
              label="时间范围"
              onChange={(e) => setTimeRange(e.target.value)}
            >
              <MenuItem value="15m">最近15分钟</MenuItem>
              <MenuItem value="1h">最近1小时</MenuItem>
              <MenuItem value="6h">最近6小时</MenuItem>
              <MenuItem value="24h">最近24小时</MenuItem>
              <MenuItem value="7d">最近7天</MenuItem>
            </Select>
          </FormControl>
        </Grid>
        <Grid item xs={12} md={3}>
          <TextField
            fullWidth
            label="搜索日志"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            InputProps={{
              endAdornment: (
                <IconButton>
                  <SearchIcon />
                </IconButton>
              ),
            }}
          />
        </Grid>
        <Grid item xs={12} md={2}>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button
              variant="outlined"
              startIcon={<RefreshIcon />}
              onClick={() => {/* 刷新日志 */}}
            >
              刷新
            </Button>
            <Button
              variant="outlined"
              startIcon={<DownloadIcon />}
              onClick={() => {/* 下载日志 */}}
            >
              导出
            </Button>
          </Box>
        </Grid>
      </Grid>

      <Paper sx={{ height: 'calc(100vh - 300px)' }}>
        <DataGrid
          rows={sampleData}
          columns={columns}
          pageSize={25}
          rowsPerPageOptions={[25]}
          disableSelectionOnClick
          density="compact"
        />
      </Paper>
    </Box>
  );
} 