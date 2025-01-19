'use client';

import {
    List,
    Datagrid,
    TextField,
    BooleanField,
    DateField,
    FilterButton,
    CreateButton,
    ExportButton,
    TopToolbar,
    SelectInput,
    TextInput,
} from 'react-admin';

const filters = [
    <TextInput source="name" label="服务名称" alwaysOn />,
    <SelectInput source="status" label="状态" choices={[
        { id: 'active', name: '运行中' },
        { id: 'inactive', name: '已停止' },
        { id: 'failed', name: '故障' },
    ]} />,
];

const ListActions = () => (
    <TopToolbar>
        <FilterButton />
        <CreateButton />
        <ExportButton />
    </TopToolbar>
);

export const ServiceList = () => (
    <List 
        filters={filters}
        actions={<ListActions />}
        sort={{ field: 'name', order: 'ASC' }}
    >
        <Datagrid>
            <TextField source="name" label="服务名称" />
            <TextField source="description" label="描述" />
            <BooleanField source="isRunning" label="运行状态" />
            <TextField source="status" label="状态详情" />
            <TextField source="port" label="端口" />
            <DateField source="lastStart" label="最后启动时间" showTime />
            <DateField source="lastStop" label="最后停止时间" showTime />
        </Datagrid>
    </List>
); 