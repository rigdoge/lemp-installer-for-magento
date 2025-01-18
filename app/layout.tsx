'use client';

import React from 'react';
import { Admin, Resource } from 'react-admin';
import simpleRestProvider from 'ra-data-simple-rest';

const dataProvider = simpleRestProvider('/api');

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh">
      <head>
        <title>LEMP Stack Manager</title>
        <meta name="description" content="LEMP Stack Manager for Magento" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </head>
      <body>
        <Admin 
          dataProvider={dataProvider}
          darkTheme={{ palette: { mode: 'dark' } }}
          defaultTheme="dark"
        >
          {children}
        </Admin>
      </body>
    </html>
  );
} 