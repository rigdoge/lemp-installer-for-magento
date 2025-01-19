'use client';

import { useState } from 'react';
import { Box } from '@mui/material';
import Header from './components/Header';
import Sidebar from './components/Sidebar';
import { ThemeProvider } from './contexts/ThemeContext';

const drawerWidth = 240;

export default function RootLayoutClient({
  children,
}: {
  children: React.ReactNode;
}) {
  const [drawerOpen, setDrawerOpen] = useState(true);

  const handleDrawerToggle = () => {
    setDrawerOpen(!drawerOpen);
  };

  return (
    <ThemeProvider>
      <Box sx={{ display: 'flex', minHeight: '100vh' }}>
        <Header open={drawerOpen} onDrawerToggle={handleDrawerToggle} />
        <Sidebar open={drawerOpen} />
        <Box
          component="main"
          sx={{
            flexGrow: 1,
            p: 0,
            width: { sm: `calc(100% - ${drawerWidth}px)` },
            ml: { sm: drawerOpen ? `${drawerWidth}px` : 0 },
            transition: theme => theme.transitions.create('margin', {
              easing: theme.transitions.easing.sharp,
              duration: theme.transitions.duration.leavingScreen,
            }),
            mt: '64px', // 为顶部 AppBar 留出空间
          }}
        >
          {children}
        </Box>
      </Box>
    </ThemeProvider>
  );
} 