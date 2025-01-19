'use client';

import React, { useState } from 'react';
import { AppBar, Box, IconButton, Toolbar, Typography } from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import Sidebar from './components/layout/Sidebar';
import ThemeToggle from './components/ThemeToggle';
import { ColorModeProvider } from './contexts/ColorModeContext';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  return (
    <html lang="zh">
      <body style={{ margin: 0 }}>
        <ColorModeProvider>
          <Box sx={{ display: 'flex' }}>
            <AppBar position="fixed">
              <Toolbar>
                <IconButton
                  color="inherit"
                  edge="start"
                  onClick={() => setIsSidebarOpen(true)}
                  sx={{ mr: 2 }}
                >
                  <MenuIcon />
                </IconButton>
                <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                  LEMP 管理面板
                </Typography>
                <ThemeToggle />
              </Toolbar>
            </AppBar>
            <Sidebar open={isSidebarOpen} onClose={() => setIsSidebarOpen(false)} />
            <Box
              component="main"
              sx={{
                flexGrow: 1,
                mt: '64px', // AppBar 的高度
                minHeight: 'calc(100vh - 64px)',
                backgroundColor: 'background.default',
              }}
            >
              {children}
            </Box>
          </Box>
        </ColorModeProvider>
      </body>
    </html>
  );
} 