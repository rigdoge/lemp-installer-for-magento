'use client';

import { AppBar, Toolbar, Typography, Box, IconButton } from '@mui/material';
import { styled } from '@mui/material/styles';
import { Menu as MenuIcon } from '@mui/icons-material';
import ThemeToggle from './ThemeToggle';

interface HeaderProps {
  open: boolean;
  onDrawerToggle: () => void;
}

const drawerWidth = 240;

const StyledAppBar = styled(AppBar)(({ theme }) => ({
  zIndex: theme.zIndex.drawer + 1,
}));

export default function Header({ open, onDrawerToggle }: HeaderProps) {
  return (
    <StyledAppBar position="fixed">
      <Toolbar>
        <IconButton
          color="inherit"
          aria-label="open drawer"
          onClick={onDrawerToggle}
          edge="start"
          sx={{
            marginRight: 2,
          }}
        >
          <MenuIcon />
        </IconButton>
        <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
          LEMP Manager
        </Typography>
        <ThemeToggle />
      </Toolbar>
    </StyledAppBar>
  );
} 