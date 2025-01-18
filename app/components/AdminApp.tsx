'use client';

import React, { useState } from 'react';
import { Box, Container, Paper, Tab, Tabs } from '@mui/material';
import dynamic from 'next/dynamic';

const PrometheusMonitor = dynamic(() => import('./monitoring/PrometheusMonitor'), { ssr: false });
const PrometheusConfig = dynamic(() => import('./monitoring/PrometheusConfig'), { ssr: false });
const TelegramConfig = dynamic(() => import('./notifications/TelegramConfig'), { ssr: false });

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`tabpanel-${index}`}
      aria-labelledby={`tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

export default function AdminApp() {
  const [tabValue, setTabValue] = React.useState(0);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  return (
    <Container maxWidth="md" sx={{ py: 4 }}>
      <Paper sx={{ width: '100%', mb: 2 }}>
        <Tabs
          value={tabValue}
          onChange={handleTabChange}
          aria-label="管理面板"
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab label="系统监控" />
          <Tab label="监控配置" />
          <Tab label="通知配置" />
        </Tabs>

        <TabPanel value={tabValue} index={0}>
          <PrometheusMonitor />
        </TabPanel>
        <TabPanel value={tabValue} index={1}>
          <PrometheusConfig />
        </TabPanel>
        <TabPanel value={tabValue} index={2}>
          <TelegramConfig />
        </TabPanel>
      </Paper>
    </Container>
  );
} 