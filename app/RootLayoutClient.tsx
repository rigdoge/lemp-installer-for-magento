'use client';

import { Box } from '@mui/material';
import Header from './components/layout/Header';
import Sidebar from './components/layout/Sidebar';
import { useState } from 'react';

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
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <Header open={drawerOpen} onDrawerToggle={handleDrawerToggle} />
      <Sidebar open={drawerOpen} onClose={handleDrawerToggle} />
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          mt: 8,
          ml: drawerOpen ? 32 : 8,
          transition: 'margin 225ms cubic-bezier(0.4, 0, 0.6, 1) 0ms',
        }}
      >
        {children}
      </Box>
    </Box>
  );
} 