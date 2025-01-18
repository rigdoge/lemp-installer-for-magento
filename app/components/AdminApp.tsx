'use client';

import React from 'react';
import dynamic from 'next/dynamic';
import { Box, Tab, Tabs } from '@mui/material';

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
    <Box sx={{ width: '100%' }}>
      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={tabValue} onChange={handleChange}>
          <Tab label="系统监控" />
          <Tab label="监控配置" />
        </Tabs>
      </Box>
      <TabPanel value={tabValue} index={0}>
        <PrometheusMonitor />
      </TabPanel>
      <TabPanel value={tabValue} index={1}>
        <PrometheusConfig />
      </TabPanel>
    </Box>
  );
} 