'use client';

import React from 'react';
import { Box, Container, Tab, Tabs } from '@mui/material';
import { useState } from 'react';
import dynamic from 'next/dynamic';

const NginxMonitor = dynamic(() => import('./monitoring/nginx/NginxMonitor'), { ssr: false });
const TelegramConfig = dynamic(() => import('./notifications/TelegramConfig'), { ssr: false });

export default function AdminApp() {
  const [currentTab, setCurrentTab] = useState(0);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setCurrentTab(newValue);
  };

  return (
    <Container>
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={currentTab} onChange={handleTabChange}>
          <Tab label="Nginx 监控" />
          <Tab label="Telegram 配置" />
        </Tabs>
      </Box>

      {currentTab === 0 && <NginxMonitor />}
      {currentTab === 1 && <TelegramConfig />}
    </Container>
  );
}