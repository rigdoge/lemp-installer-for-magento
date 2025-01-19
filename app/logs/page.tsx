'use client';

import React from 'react';
import {
  List,
  Datagrid,
  TextField,
  DateField,
  SelectInput,
  TextInput,
  FilterButton,
  FilterForm,
  ListBase,
  Pagination,
} from 'react-admin';
import { Card, CardContent, Box } from '@mui/material';

const logLevels = [
  { id: 'ERROR', name: 'ERROR' },
  { id: 'WARNING', name: 'WARNING' },
  { id: 'INFO', name: 'INFO' },
  { id: 'DEBUG', name: 'DEBUG' },
];

const logSources = [
  { id: 'nginx-access', name: 'Nginx 访问日志' },
  { id: 'nginx-error', name: 'Nginx 错误日志' },
  { id: 'php-fpm', name: 'PHP-FPM 日志' },
  { id: 'mysql-error', name: 'MySQL 错误日志' },
  { id: 'magento-system', name: 'Magento 系统日志' },
  { id: 'magento-exception', name: 'Magento 异常日志' },
  { id: 'redis', name: 'Redis 日志' },
  { id: 'varnish', name: 'Varnish 日志' },
  { id: 'rabbitmq', name: 'RabbitMQ 日志' },
  { id: 'opensearch', name: 'OpenSearch 日志' },
  { id: 'system', name: 'System 日志' },
];

const LogFilters = [
  <SelectInput key="level" source="level" choices={logLevels} alwaysOn />,
  <SelectInput key="source" source="source" choices={logSources} alwaysOn />,
  <TextInput key="search" source="q" label="搜索" alwaysOn />,
];

function LogListComponent() {
  return (
    <List
      filters={LogFilters}
      sort={{ field: 'timestamp', order: 'DESC' }}
      perPage={25}
      pagination={<Pagination rowsPerPageOptions={[10, 25, 50, 100]} />}
    >
      <Datagrid bulkActionButtons={false}>
        <DateField source="timestamp" showTime />
        <TextField source="level" />
        <TextField source="source" />
        <TextField source="message" />
      </Datagrid>
    </List>
  );
}

export default function LogsPage() {
  return <LogListComponent />;
} 