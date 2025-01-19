import React from 'react';
import {
  List,
  Datagrid,
  TextField,
  UrlField,
  TextInput,
  FilterButton,
  FilterForm,
  ListBase,
  Pagination,
  Create,
  SimpleForm,
  required,
} from 'react-admin';
import { Card, CardContent, Box } from '@mui/material';

const MagentoFilters = [
  <TextInput source="q" label="搜索" alwaysOn />,
];

export const MagentoList = () => (
  <List
    filters={MagentoFilters}
    sort={{ field: 'name', order: 'ASC' }}
    perPage={25}
    pagination={<Pagination rowsPerPageOptions={[10, 25, 50, 100]} />}
  >
    <Datagrid bulkActionButtons={false}>
      <TextField source="name" />
      <UrlField source="url" />
      <TextField source="status" />
      <TextField source="version" />
    </Datagrid>
  </List>
);

export const MagentoCreate = () => (
  <Create>
    <SimpleForm>
      <TextInput source="name" validate={[required()]} />
      <TextInput source="url" validate={[required()]} />
      <TextInput source="version" validate={[required()]} />
    </SimpleForm>
  </Create>
); 