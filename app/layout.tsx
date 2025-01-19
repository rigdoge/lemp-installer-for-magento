import type { Metadata } from 'next';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v14-appRouter';
import { AuthProvider } from './contexts/AuthContext';
import ThemeRegistry from './components/ThemeRegistry/ThemeRegistry';

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
          <ThemeRegistry>
            <AuthProvider>
              {children}
            </AuthProvider>
          </ThemeRegistry>
        </AppRouterCacheProvider>
      </body>
    </html>
  );
} 