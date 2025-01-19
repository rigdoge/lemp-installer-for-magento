'use client';

import { useEffect, useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  IconButton,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Button,
} from '@mui/material';
import {
  Search as SearchIcon,
  Refresh as RefreshIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';

interface LogEntry {
  id: number;
  timestamp: string;
  level: string;
  source: string;
  message: string;
}

const logLevels = ['ALL', 'ERROR', 'WARN', 'INFO', 'DEBUG'];
const logSources = ['nginx', 'php-fpm', 'mysql', 'redis', 'system'];

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN');
};

const columns: GridColDef[] = [
  {
    field: 'timestamp',
    headerName: '时间',
    width: 200,
    renderCell: (params) => formatDate(params.row.timestamp),
  },
  { field: 'level', headerName: '级别', width: 100 },
  { field: 'source', headerName: '来源', width: 120 },
  { field: 'message', headerName: '消息', flex: 1, minWidth: 300 },
];

export default function LogsPage() {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedLevel, setSelectedLevel] = useState('ALL');
  const [selectedSource, setSelectedSource] = useState('ALL');
  const [error, setError] = useState<string | null>(null);

  const fetchLogs = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (searchQuery) params.append('query', searchQuery);
      if (selectedLevel !== 'ALL') params.append('level', selectedLevel);
      if (selectedSource !== 'ALL') params.append('source', selectedSource);

      const response = await fetch(`/api/logs?${params.toString()}`);
      if (!response.ok) {
        throw new Error('Failed to fetch logs');
      }
      const data = await response.json();
      setLogs(data.hits.map((hit: any, index: number) => ({
        id: index,
        ...hit._source,
      })));
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  const handleSearch = (event: React.FormEvent) => {
    event.preventDefault();
    fetchLogs();
  };

  const handleExport = () => {
    const csvContent = [
      ['时间', '级别', '来源', '消息'],
      ...logs.map(log => [
        new Date(log.timestamp).toLocaleString('zh-CN'),
        log.level,
        log.source,
        log.message,
      ]),
    ].map(row => row.join(',')).join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `logs_${new Date().toISOString()}.csv`;
    link.click();
  };

  return (
    <Box p={3}>
      <Typography variant="h4" gutterBottom>
        日志管理
      </Typography>
      <Paper sx={{ p: 2, mb: 2 }}>
        <form onSubmit={handleSearch}>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} sm={4}>
              <TextField
                fullWidth
                label="搜索"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                InputProps={{
                  endAdornment: (
                    <IconButton type="submit">
                      <SearchIcon />
                    </IconButton>
                  ),
                }}
              />
            </Grid>
            <Grid item xs={12} sm={3}>
              <FormControl fullWidth>
                <InputLabel>日志级别</InputLabel>
                <Select
                  value={selectedLevel}
                  label="日志级别"
                  onChange={(e) => setSelectedLevel(e.target.value)}
                >
                  {logLevels.map((level) => (
                    <MenuItem key={level} value={level}>
                      {level}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={3}>
              <FormControl fullWidth>
                <InputLabel>日志来源</InputLabel>
                <Select
                  value={selectedSource}
                  label="日志来源"
                  onChange={(e) => setSelectedSource(e.target.value)}
                >
                  <MenuItem value="ALL">全部</MenuItem>
                  {logSources.map((source) => (
                    <MenuItem key={source} value={source}>
                      {source}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={6} sm={1}>
              <IconButton onClick={fetchLogs} title="刷新">
                <RefreshIcon />
              </IconButton>
            </Grid>
            <Grid item xs={6} sm={1}>
              <IconButton onClick={handleExport} title="导出">
                <DownloadIcon />
              </IconButton>
            </Grid>
          </Grid>
        </form>
      </Paper>

      {error ? (
        <Typography color="error" sx={{ mb: 2 }}>
          {error}
        </Typography>
      ) : (
        <Paper sx={{ height: 600 }}>
          <DataGrid
            rows={logs}
            columns={columns}
            loading={loading}
            pageSizeOptions={[10, 25, 50, 100]}
            disableRowSelectionOnClick
            initialState={{
              pagination: { paginationModel: { pageSize: 25 } },
            }}
          />
        </Paper>
      )}
    </Box>
  );
} 