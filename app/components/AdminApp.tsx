'use client';

import React from 'react';
import dynamic from 'next/dynamic';
import { Box, Tab, Tabs, AppBar, Toolbar, Typography } from '@mui/material';
import ThemeToggle from './ThemeToggle';

const PrometheusMonitor = dynamic(() => import('./monitoring/PrometheusMonitor'), { ssr: false });
const PrometheusConfig = dynamic(() => import('./monitoring/PrometheusConfig'), { ssr: false });

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
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
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

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            LEMP Stack Manager
          </Typography>
          <ThemeToggle />
        </Toolbar>
        <Tabs value={tabValue} onChange={handleChange}>
          <Tab label="系统概览" />
          <Tab label="系统监控" />
          <Tab label="通知设置" />
        </Tabs>
      </AppBar>
      <TabPanel value={tabValue} index={0}>
        系统概览
      </TabPanel>
      <TabPanel value={tabValue} index={1}>
        <PrometheusMonitor />
      </TabPanel>
      <TabPanel value={tabValue} index={2}>
        <PrometheusConfig />
      </TabPanel>
    </Box>
  );
} 