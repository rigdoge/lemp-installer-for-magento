import { I18nProvider } from 'react-admin';
import polyglotI18nProvider from 'ra-i18n-polyglot';
import chineseMessages from 'ra-language-chinese';

const translations = {
  ...chineseMessages,
  ra: {
    ...chineseMessages.ra,
    language: 'zh',
  },
  resources: {
    logs: {
      name: '日志管理',
      fields: {
        timestamp: '时间',
        level: '级别',
        source: '来源',
        message: '消息',
      },
    },
    monitoring: {
      name: '系统监控',
      fields: {
        name: '名称',
        status: '状态',
        value: '数值',
        timestamp: '时间',
      },
    },
    notifications: {
      name: '通知中心',
      fields: {
        title: '标题',
        message: '内容',
        type: '类型',
        status: '状态',
        created_at: '创建时间',
      },
    },
    magento: {
      name: 'Magento 站点',
      fields: {
        name: '名称',
        url: '网址',
        status: '状态',
        version: '版本',
      },
    },
  },
  // 自定义翻译
  custom: {
    dashboard: {
      title: '仪表板',
      welcome: '欢迎使用 LEMP 管理面板',
      systemStatus: '系统状态',
      magentoStatus: 'Magento 状态',
      serviceStatus: '服务状态',
    },
    common: {
      refresh: '刷新',
      export: '导出',
      search: '搜索',
      filter: '筛选',
      timeRange: '时间范围',
      lastMinutes: '最近 {n} 分钟',
      lastHours: '最近 {n} 小时',
      lastDays: '最近 {n} 天',
    },
  },
};

export const i18nProvider = polyglotI18nProvider(() => translations, 'zh'); 