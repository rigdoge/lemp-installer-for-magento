'use client';

import { Admin, Resource } from 'react-admin';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { theme } from './theme';
import { authProvider } from './providers/authProvider';
import { dataProvider } from './providers/dataProvider';
import { i18nProvider } from './providers/i18nProvider';

// Icons
import DashboardIcon from '@mui/icons-material/Dashboard';
import StorageIcon from '@mui/icons-material/Storage';
import AssessmentIcon from '@mui/icons-material/Assessment';
import MonitorHeartIcon from '@mui/icons-material/MonitorHeart';
import NotificationsIcon from '@mui/icons-material/Notifications';

// Resources
import { Dashboard } from './components/Dashboard';
import { LogList } from './resources/logs';
import { MonitoringList } from './resources/monitoring';
import { NotificationList } from './resources/notifications';
import { MagentoList } from './resources/magento';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh-CN">
      <body>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <Admin
            dataProvider={dataProvider}
            authProvider={authProvider}
            i18nProvider={i18nProvider}
            dashboard={Dashboard}
            darkTheme={theme}
            defaultTheme="light"
          >
            <Resource
              name="magento"
              list={MagentoList}
              icon={StorageIcon}
              options={{ label: 'Magento 站点' }}
            />
            <Resource
              name="monitoring"
              list={MonitoringList}
              icon={MonitorHeartIcon}
              options={{ label: '系统监控' }}
            />
            <Resource
              name="logs"
              list={LogList}
              icon={AssessmentIcon}
              options={{ label: '日志管理' }}
            />
            <Resource
              name="notifications"
              list={NotificationList}
              icon={NotificationsIcon}
              options={{ label: '通知中心' }}
            />
          </Admin>
        </ThemeProvider>
      </body>
    </html>
  );
} 