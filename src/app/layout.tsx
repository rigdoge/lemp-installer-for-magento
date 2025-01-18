import React from 'react';

export const metadata = {
  title: 'LEMP Stack Manager',
  description: 'A comprehensive tool for managing LEMP stack services',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh">
      <body>{children}</body>
    </html>
  );
} 