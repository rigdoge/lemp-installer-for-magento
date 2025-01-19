'use client';

import { AppRouterCacheProvider } from '@mui/material-nextjs/v14-appRouter';
import { ThemeProvider } from '@mui/material/styles';
import { theme } from './theme';
import ClientOnly from './components/ClientOnly';
import CssBaseline from '@mui/material/CssBaseline';

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
          {children}
        </ClientOnly>
      </ThemeProvider>
    </AppRouterCacheProvider>
  );
} 