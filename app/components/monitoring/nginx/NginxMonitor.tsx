'use client';

import React, { useRef } from 'react';
import { Card, CardContent, Typography, Grid, Box, styled } from '@mui/material';
import { Title } from 'react-admin';
import { useServiceMonitor } from '@/hooks/useServiceMonitor';
import { NginxStatus } from '@/types/monitoring';
import { NotificationMessage } from '@/types/notification';

// 定义状态点的类型
type StatusType = 'normal' | 'warning' | 'error';

// 状态方块组件
const StatusBlock = styled('div')<{ status: StatusType }>(({ status }) => ({
    width: 16,
    height: 16,
    backgroundColor: status === 'normal' ? '#4caf50' : 
                    status === 'warning' ? '#ff9800' : '#f44336',
    margin: '0 2px',
    transition: 'all 0.3s ease',
    cursor: 'pointer',
    '&:hover': {
        transform: 'scale(1.2)',
        boxShadow: status === 'normal' ? '0 0 8px #4caf50' :
                   status === 'warning' ? '0 0 8px #ff9800' : '0 0 8px #f44336',
    }
}));

// 状态条组件
const StatusBar = ({ points = 30, threshold = 0, value = 0 }: { 
    points?: number;
    threshold?: number;
    value?: number;
}) => {
    // 基于阈值判断状态
    const getStatus = (value: number, threshold: number): StatusType => {
        if (value > threshold * 1.5) return 'error';
        if (value > threshold) return 'warning';
        return 'normal';
    };

    // 生成状态数据
    const blocks = Array.from({ length: points }, (_, index) => {
        // 这里模拟数据，实际应该使用真实的历史数据
        const simulatedValue = value * (0.8 + Math.random() * 0.4); // 在当前值的 ±20% 范围内波动
        return getStatus(simulatedValue, threshold);
    });

    return (
        <Box sx={{ 
            display: 'flex', 
            alignItems: 'center', 
            gap: '2px',
            backgroundColor: 'rgba(255, 255, 255, 0.1)',
            padding: '8px',
            borderRadius: '4px'
        }}>
            {blocks.map((status, index) => (
                <StatusBlock 
                    key={index} 
                    status={status}
                    title={`Status at ${index} minutes ago`}
                />
            ))}
        </Box>
    );
};

const MetricRow = ({ 
    label, 
    value, 
    unit,
    threshold 
}: { 
    label: string; 
    value: number;
    unit: string;
    threshold: number;
}) => (
    <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
            <Typography variant="body1" color="textSecondary">
                {label}
            </Typography>
            <Typography variant="body1">
                {value.toLocaleString()} {unit}
            </Typography>
        </Box>
        <StatusBar points={30} threshold={threshold} value={value} />
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
            <Typography variant="caption" color="textSecondary">
                43m ago
            </Typography>
            <Typography variant="caption" color="textSecondary">
                now
            </Typography>
        </Box>
    </Box>
);

export const NginxMonitor: React.FC = () => {
    const { status: serviceStatus, error, loading } = useServiceMonitor('nginx');
    const status = serviceStatus as NginxStatus | null;

    // 使用 ref 来跟踪上一次的状态
    const prevStatus = useRef<boolean | null>(null);

    if (loading) {
        return (
            <Box sx={{ p: 2 }}>
                <StatusBar points={30} />
            </Box>
        );
    }

    if (error || !status) {
        return (
            <Box sx={{ p: 2 }}>
                <Typography color="error">
                    {error || 'No data available'}
                </Typography>
            </Box>
        );
    }

    return (
        <Card>
            <Title title="Nginx Status" />
            <CardContent>
                <Box sx={{ mb: 4 }}>
                    <Grid container spacing={3}>
                        <Grid item xs={12}>
                            <MetricRow 
                                label="Active Connections"
                                value={status.connections.active}
                                unit="connections"
                                threshold={1000} // 假设超过1000连接就警告
                            />
                            <MetricRow 
                                label="Requests per Second"
                                value={status.requests.perSecond}
                                unit="req/s"
                                threshold={100} // 假设超过100请求/秒就警告
                            />
                            <MetricRow 
                                label="Worker Processes"
                                value={status.workers.busy}
                                unit="busy / total"
                                threshold={status.workers.total * 0.8} // 超过80%的工作进程忙碌就警告
                            />
                            <MetricRow 
                                label="Connection Writing"
                                value={status.connections.writing}
                                unit="connections"
                                threshold={500} // 假设超过500写连接就警告
                            />
                        </Grid>
                    </Grid>
                </Box>
            </CardContent>
        </Card>
    );
}; 