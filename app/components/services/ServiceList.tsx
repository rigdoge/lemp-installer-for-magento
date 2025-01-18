'use client';

import React from 'react';
import { List, Datagrid, TextField, BooleanField } from 'react-admin';

export const ServiceList = () => (
  <List>
    <Datagrid>
      <TextField source="id" />
      <TextField source="name" />
      <TextField source="status" />
      <BooleanField source="isRunning" />
      <TextField source="uptime" />
      <TextField source="memory" />
      <TextField source="cpu" />
    </Datagrid>
  </List>
); 