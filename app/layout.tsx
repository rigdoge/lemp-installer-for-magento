'use client';

import { Inter } from 'next/font/google';
import { ColorModeProvider } from './contexts/ColorModeContext';

const inter = Inter({ subsets: ['latin'] });

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh">
      <body className={inter.className}>
        <ColorModeProvider>
          {children}
        </ColorModeProvider>
      </body>
    </html>
  );
} 