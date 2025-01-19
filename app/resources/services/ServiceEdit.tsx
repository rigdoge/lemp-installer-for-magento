'use client';

import {
    Edit,
    SimpleForm,
    TextInput,
    NumberInput,
    BooleanInput,
    SelectInput,
    required,
} from 'react-admin';

export const ServiceEdit = () => (
    <Edit>
        <SimpleForm>
            <TextInput source="name" label="服务名称" validate={[required()]} />
            <TextInput source="description" label="描述" multiline rows={3} />
            <SelectInput source="status" label="状态" choices={[
                { id: 'active', name: '运行中' },
                { id: 'inactive', name: '已停止' },
                { id: 'failed', name: '故障' },
            ]} validate={[required()]} />
            <NumberInput source="port" label="端口" validate={[required()]} />
            <BooleanInput source="autostart" label="开机自启" />
        </SimpleForm>
    </Edit>
); 