'use client';

import { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  Paper,
} from '@mui/material';
import {
  DataGrid,
  GridColDef,
  GridRenderCellParams,
} from '@mui/x-data-grid';
import { Add as AddIcon, Delete as DeleteIcon, Key as KeyIcon } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';

interface User {
  username: string;
  role: 'admin' | 'user';
  createdAt: string;
  lastLogin?: string;
}

interface NewUserData {
  username: string;
  password: string;
  role: 'admin' | 'user';
}

interface ResetPasswordData {
  username: string;
  newPassword: string;
}

export default function UsersPage() {
  const { user } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // 对话框状态
  const [newUserDialogOpen, setNewUserDialogOpen] = useState(false);
  const [resetPasswordDialogOpen, setResetPasswordDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<string | null>(null);
  
  // 表单数据
  const [newUser, setNewUser] = useState<NewUserData>({
    username: '',
    password: '',
    role: 'user',
  });
  const [newPassword, setNewPassword] = useState('');

  // 加载用户列表
  const fetchUsers = async () => {
    try {
      const response = await fetch('/api/users');
      if (!response.ok) {
        throw new Error('获取用户列表失败');
      }
      const data = await response.json();
      setUsers(data);
    } catch (error) {
      setError(error instanceof Error ? error.message : '获取用户列表失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  // 创建新用户
  const handleCreateUser = async () => {
    try {
      const response = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newUser),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || '创建用户失败');
      }

      await fetchUsers();
      setNewUserDialogOpen(false);
      setNewUser({ username: '', password: '', role: 'user' });
    } catch (error) {
      setError(error instanceof Error ? error.message : '创建用户失败');
    }
  };

  // 删除用户
  const handleDeleteUser = async (username: string) => {
    if (!window.confirm('确定要删除此用户吗？')) {
      return;
    }

    try {
      const response = await fetch('/api/users', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || '删除用户失败');
      }

      await fetchUsers();
    } catch (error) {
      setError(error instanceof Error ? error.message : '删除用户失败');
    }
  };

  // 重置密码
  const handleResetPassword = async () => {
    if (!selectedUser) return;

    try {
      const response = await fetch('/api/users', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: selectedUser,
          newPassword,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || '重置密码失败');
      }

      setResetPasswordDialogOpen(false);
      setSelectedUser(null);
      setNewPassword('');
    } catch (error) {
      setError(error instanceof Error ? error.message : '重置密码失败');
    }
  };

  const columns: GridColDef[] = [
    { field: 'username', headerName: '用户名', flex: 1 },
    { field: 'role', headerName: '角色', width: 120 },
    {
      field: 'createdAt',
      headerName: '创建时间',
      flex: 1,
      valueFormatter: (params) => {
        return new Date(params.value).toLocaleString();
      },
    },
    {
      field: 'lastLogin',
      headerName: '最后登录',
      flex: 1,
      valueFormatter: (params) => {
        return params.value ? new Date(params.value).toLocaleString() : '从未登录';
      },
    },
    {
      field: 'actions',
      headerName: '操作',
      width: 120,
      renderCell: (params: GridRenderCellParams) => (
        <Box>
          <Tooltip title="重置密码">
            <IconButton
              onClick={() => {
                setSelectedUser(params.row.username);
                setResetPasswordDialogOpen(true);
              }}
              disabled={params.row.username === user?.username}
            >
              <KeyIcon />
            </IconButton>
          </Tooltip>
          <Tooltip title="删除用户">
            <IconButton
              onClick={() => handleDeleteUser(params.row.username)}
              disabled={params.row.username === 'admin' || params.row.username === user?.username}
            >
              <DeleteIcon />
            </IconButton>
          </Tooltip>
        </Box>
      ),
    },
  ];

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">用户管理</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewUserDialogOpen(true)}
        >
          新建用户
        </Button>
      </Box>

      {error && (
        <Typography color="error" mb={2}>
          {error}
        </Typography>
      )}

      <Paper elevation={3}>
        <DataGrid
          rows={users}
          columns={columns}
          getRowId={(row) => row.username}
          autoHeight
          loading={loading}
          disableRowSelectionOnClick
          initialState={{
            pagination: { paginationModel: { pageSize: 10 } },
          }}
          pageSizeOptions={[10, 25, 50]}
        />
      </Paper>

      {/* 新建用户对话框 */}
      <Dialog open={newUserDialogOpen} onClose={() => setNewUserDialogOpen(false)}>
        <DialogTitle>新建用户</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="用户名"
            fullWidth
            value={newUser.username}
            onChange={(e) => setNewUser({ ...newUser, username: e.target.value })}
          />
          <TextField
            margin="dense"
            label="密码"
            type="password"
            fullWidth
            value={newUser.password}
            onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
          />
          <FormControl fullWidth margin="dense">
            <InputLabel>角色</InputLabel>
            <Select
              value={newUser.role}
              label="角色"
              onChange={(e) => setNewUser({ ...newUser, role: e.target.value as 'admin' | 'user' })}
            >
              <MenuItem value="user">普通用户</MenuItem>
              <MenuItem value="admin">管理员</MenuItem>
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewUserDialogOpen(false)}>取消</Button>
          <Button onClick={handleCreateUser} variant="contained">
            创建
          </Button>
        </DialogActions>
      </Dialog>

      {/* 重置密码对话框 */}
      <Dialog open={resetPasswordDialogOpen} onClose={() => setResetPasswordDialogOpen(false)}>
        <DialogTitle>重置密码</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="新密码"
            type="password"
            fullWidth
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setResetPasswordDialogOpen(false)}>取消</Button>
          <Button onClick={handleResetPassword} variant="contained">
            确认
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
} 