'use client';

import React from 'react';
import { Admin, Resource } from 'react-admin';
import simpleRestProvider from 'ra-data-simple-rest';
import { NginxMonitor } from './monitoring/nginx/NginxMonitor';
import { TelegramConfig } from './notifications/TelegramConfig';

const dataProvider = simpleRestProvider('/api');

export default function AdminApp() {
    return (
        <Admin
            dataProvider={dataProvider}
            darkTheme={{ palette: { mode: 'dark' } }}
            defaultTheme="dark"
        >
            <Resource
                name="nginx"
                list={NginxMonitor}
                options={{ label: 'Nginx 监控' }}
            />
            <Resource
                name="telegram"
                list={TelegramConfig}
                options={{ label: 'Telegram 配置' }}
            />
        </Admin>
    );
} 