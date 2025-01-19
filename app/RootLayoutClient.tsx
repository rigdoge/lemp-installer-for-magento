'use client';

import { AppRouterCacheProvider } from '@mui/material-nextjs/v14-appRouter';
import { ThemeProvider } from '@mui/material/styles';
import { theme } from './theme';
import ClientOnly from './components/ClientOnly';
import CssBaseline from '@mui/material/CssBaseline';
import Header from './components/Header';
import Sidebar from './components/Sidebar';
import { Box, Toolbar } from '@mui/material';

export default function RootLayoutClient({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AppRouterCacheProvider>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <ClientOnly>
          <Box sx={{ display: 'flex' }}>
            <Header />
            <Sidebar />
            <Box
              component="main"
              sx={{
                flexGrow: 1,
                p: 3,
                width: { sm: `calc(100% - 240px)` },
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