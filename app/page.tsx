'use client';

import { Box, Typography } from '@mui/material';
import SystemOverview from './components/dashboard/SystemOverview';

export default function HomePage() {
  return (
    <Box p={3}>
      <Typography variant="h4" gutterBottom>
        系统概览
      </Typography>
      <SystemOverview />
    </Box>
  );
} 