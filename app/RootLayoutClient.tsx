'use client';

import { useState } from 'react';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v14-appRouter';
import CssBaseline from '@mui/material/CssBaseline';
import Header from './components/Header';
import Sidebar from './components/Sidebar';
import { Box, Toolbar } from '@mui/material';
import { ThemeProvider } from './contexts/ThemeContext';
import ClientOnly from './components/ClientOnly';

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
    <AppRouterCacheProvider>
      <ThemeProvider>
        <CssBaseline />
        <ClientOnly>
          <Box sx={{ display: 'flex' }}>
            <Header open={drawerOpen} onDrawerToggle={handleDrawerToggle} />
            <Sidebar open={drawerOpen} />
            <Box
              component="main"
              sx={{
                flexGrow: 1,
                p: 3,
                width: { sm: `calc(100% - ${drawerOpen ? 240 : 64}px)` },
                marginLeft: { sm: drawerOpen ? 0 : -176 },
                transition: theme => theme.transitions.create(['margin', 'width'], {
                  easing: theme.transitions.easing.sharp,
                  duration: theme.transitions.duration.enteringScreen,
                }),
              }}
            >
              <Toolbar />
              {children}
            </Box>
          </Box>
        </ClientOnly>
      </ThemeProvider>
    </AppRouterCacheProvider>
  );
} 