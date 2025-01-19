import React from 'react';
import {
  List,
  Datagrid,
  TextField,
  DateField,
  NumberField,
  SelectInput,
  FilterButton,
  FilterForm,
  ListBase,
  Pagination,
} from 'react-admin';
import { Card, CardContent, Box } from '@mui/material';

const metricTypes = [
  { id: 'cpu', name: 'CPU 使用率' },
  { id: 'memory', name: '内存使用率' },
  { id: 'disk', name: '磁盘使用率' },
  { id: 'network', name: '网络流量' },
  { id: 'nginx', name: 'Nginx 状态' },
  { id: 'php-fpm', name: 'PHP-FPM 状态' },
  { id: 'mysql', name: 'MySQL 状态' },
  { id: 'redis', name: 'Redis 状态' },
  { id: 'varnish', name: 'Varnish 状态' },
  { id: 'rabbitmq', name: 'RabbitMQ 状态' },
  { id: 'opensearch', name: 'OpenSearch 状态' },
];

const MonitoringFilters = [
  <SelectInput source="type" choices={metricTypes} alwaysOn />,
];

export const MonitoringList = () => (
  <List
    filters={MonitoringFilters}
    sort={{ field: 'timestamp', order: 'DESC' }}
    perPage={25}
    pagination={<Pagination rowsPerPageOptions={[10, 25, 50, 100]} />}
  >
    <Datagrid bulkActionButtons={false}>
      <DateField source="timestamp" showTime />
      <TextField source="name" />
      <TextField source="status" />
      <NumberField source="value" />
    </Datagrid>
  </List>
); 