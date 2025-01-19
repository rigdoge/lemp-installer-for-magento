'use client';

import { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Alert,
} from '@mui/material';
import { useAuth } from '../contexts/AuthContext';

interface ChangePasswordDialogProps {
  open: boolean;
  onClose: () => void;
}

export default function ChangePasswordDialog({
  open,
  onClose,
}: ChangePasswordDialogProps) {
  const { changePassword } = useAuth();
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (newPassword !== confirmPassword) {
      setError('新密码两次输入不一致');
      return;
    }

    if (newPassword.length < 6) {
      setError('新密码长度不能小于6位');
      return;
    }

    setLoading(true);
    try {
      await changePassword(currentPassword, newPassword);
      onClose();
      // 重置表单
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (err) {
      setError(err instanceof Error ? err.message : '修改密码失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogTitle>修改密码</DialogTitle>
      <form onSubmit={handleSubmit}>
        <DialogContent>
          <TextField
            fullWidth
            type="password"
            label="当前密码"
            margin="normal"
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
            disabled={loading}
            required
          />
          <TextField
            fullWidth
            type="password"
            label="新密码"
            margin="normal"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            disabled={loading}
            required
          />
          <TextField
            fullWidth
            type="password"
            label="确认新密码"
            margin="normal"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            disabled={loading}
            required
          />
          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={onClose} disabled={loading}>
            取消
          </Button>
          <Button type="submit" variant="contained" disabled={loading}>
            {loading ? '提交中...' : '确认'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
} 