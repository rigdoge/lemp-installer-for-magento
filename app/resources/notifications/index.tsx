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

const notificationTypes = [
  { id: 'system', name: '系统通知' },
  { id: 'error', name: '错误通知' },
  { id: 'warning', name: '警告通知' },
  { id: 'info', name: '信息通知' },
];

const notificationStatus = [
  { id: 'unread', name: '未读' },
  { id: 'read', name: '已读' },
  { id: 'archived', name: '已归档' },
];

const NotificationFilters = [
  <SelectInput source="type" choices={notificationTypes} alwaysOn />,
  <SelectInput source="status" choices={notificationStatus} alwaysOn />,
  <TextInput source="q" label="搜索" alwaysOn />,
];

export const NotificationList = () => (
  <List
    filters={NotificationFilters}
    sort={{ field: 'created_at', order: 'DESC' }}
    perPage={25}
    pagination={<Pagination rowsPerPageOptions={[10, 25, 50, 100]} />}
  >
    <Datagrid bulkActionButtons={false}>
      <DateField source="created_at" showTime />
      <TextField source="title" />
      <TextField source="message" />
      <TextField source="type" />
      <TextField source="status" />
    </Datagrid>
  </List>
); 