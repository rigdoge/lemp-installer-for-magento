'use client';

import type { Metadata } from 'next';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v14-appRouter';
import { ThemeProvider } from '@mui/material/styles';
import { theme } from './theme';
import ClientOnly from './components/ClientOnly';
import CssBaseline from '@mui/material/CssBaseline';

export const metadata: Metadata = {
  title: 'LEMP Manager',
  description: 'LEMP stack management interface',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh">
      <body>
        <AppRouterCacheProvider>
          <ThemeProvider theme={theme}>
            <CssBaseline />
            <ClientOnly>
              {children}
            </ClientOnly>
          </ThemeProvider>
        </AppRouterCacheProvider>
      </body>
    </html>
  );
} 