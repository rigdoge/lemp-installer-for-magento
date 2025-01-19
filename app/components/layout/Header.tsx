'use client';

import {
  AppBar,
  IconButton,
  Toolbar,
  Typography,
  useTheme,
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import { useAuth } from '../../contexts/AuthContext';

interface HeaderProps {
  open: boolean;
  onDrawerToggle: () => void;
}

export default function Header({ open, onDrawerToggle }: HeaderProps) {
  const theme = useTheme();
  const { username } = useAuth();

  return (
    <AppBar
      position="fixed"
      sx={{
        width: { sm: `calc(100% - ${open ? '256px' : '64px'})` },
        ml: { sm: open ? '256px' : '64px' },
        transition: theme.transitions.create(['margin', 'width'], {
          easing: theme.transitions.easing.sharp,
          duration: theme.transitions.duration.leavingScreen,
        }),
      }}
    >
      <Toolbar>
        <IconButton
          color="inherit"
          aria-label="open drawer"
          edge="start"
          onClick={onDrawerToggle}
          sx={{ mr: 2 }}
        >
          <MenuIcon />
        </IconButton>
        <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
          LEMP Manager
        </Typography>
        <Typography variant="body1" sx={{ ml: 2 }}>
          {username}
        </Typography>
      </Toolbar>
    </AppBar>
  );
} 