'use client';

import { Admin, Resource } from 'react-admin';
import ThemeRegistry from './components/ThemeRegistry/ThemeRegistry';
import simpleRestProvider from 'ra-data-simple-rest';
import polyglotI18nProvider from 'ra-i18n-polyglot';
import chineseMessages from 'ra-language-chinese';
import authProvider from './providers/authProvider';
import { ServiceList, ServiceEdit, ServiceCreate } from './resources/services';
import SettingsSystemDaemonIcon from '@mui/icons-material/SettingsSystemDaemon';

const i18nProvider = polyglotI18nProvider(() => chineseMessages, 'zh');
const dataProvider = simpleRestProvider('/api');

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh">
      <body>
        <ThemeRegistry>
          <Admin 
            authProvider={authProvider}
            dataProvider={dataProvider}
            i18nProvider={i18nProvider}
            requireAuth
            layout={props => (
              <div style={{ height: '100vh' }}>
                {children}
              </div>
            )}
          >
            <Resource 
              name="services"
              list={ServiceList}
              edit={ServiceEdit}
              create={ServiceCreate}
              icon={SettingsSystemDaemonIcon}
              options={{ label: '服务管理' }}
            />
          </Admin>
        </ThemeRegistry>
      </body>
    </html>
  );
} 