import React from 'react';
import { Title } from 'react-admin';
import { Card, CardContent, Grid } from '@mui/material';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title as ChartTitle,
  Tooltip,
  Legend,
} from 'chart.js';
import { Line } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  ChartTitle,
  Tooltip,
  Legend
);

const options = {
  responsive: true,
  plugins: {
    legend: {
      position: 'top' as const,
    },
    title: {
      display: true,
      text: '系统资源使用趋势',
    },
  },
};

const labels = ['1分钟前', '2分钟前', '3分钟前', '4分钟前', '5分钟前'];

const data = {
  labels,
  datasets: [
    {
      label: 'CPU 使用率',
      data: [65, 59, 80, 81, 56],
      borderColor: 'rgb(255, 99, 132)',
      backgroundColor: 'rgba(255, 99, 132, 0.5)',
    },
    {
      label: '内存使用率',
      data: [28, 48, 40, 19, 86],
      borderColor: 'rgb(53, 162, 235)',
      backgroundColor: 'rgba(53, 162, 235, 0.5)',
    },
  ],
};

export const Dashboard = () => (
  <Card>
    <Title title="仪表板" />
    <CardContent>
      <Grid container spacing={2}>
        <Grid item xs={12}>
          <Line options={options} data={data} />
        </Grid>
      </Grid>
    </CardContent>
  </Card>
); 