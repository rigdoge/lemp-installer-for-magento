'use client';

import React from 'react';
import { List, Datagrid, TextField, DateField } from 'react-admin';

export const NotificationList = () => (
  <List>
    <Datagrid>
      <TextField source="id" />
      <TextField source="type" />
      <TextField source="message" />
      <DateField source="timestamp" />
      <TextField source="status" />
    </Datagrid>
  </List>
); 