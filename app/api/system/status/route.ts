import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';
import { Site } from '../../sites/route';

const execAsync = promisify(exec);
const SITES_CONFIG_PATH = path.join(process.cwd(), 'config', 'sites.json');

interface SystemStatus {
  uptime: string;
  cpu: {
    usage: number;
  };
  memory: {
    total: number;
    used: number;
    free: number;
    usage: number;
  };
  disk: {
    total: number;
    used: number;
    free: number;
    usage: number;
  };
  sites: {
    [key: string]: {
      name: string;
      path: string;
      status: {
        mode: string;
        cacheStatus: {
          enabled: number;
          total: number;
        };
        orders: {
          today: number;
        };
        activeUsers: number;
      };
    };
  };
  services: {
    [key: string]: {
      status: 'running' | 'stopped' | 'error';
      error?: string;
    };
  };
}

async function getUptime(): Promise<string> {
  try {
    const { stdout } = await execAsync('uptime -p');
    return stdout.trim();
  } catch (error) {
    console.error('Error getting uptime:', error);
    return 'Unknown';
  }
}

async function getCpuUsage(): Promise<number> {
  try {
    const { stdout } = await execAsync("top -bn1 | grep 'Cpu(s)' | awk '{print $2}'");
    return parseFloat(stdout);
  } catch (error) {
    console.error('Error getting CPU usage:', error);
    return 0;
  }
}

async function getMemoryInfo() {
  try {
    const { stdout } = await execAsync('free -b');
    const lines = stdout.split('\n');
    const memInfo = lines[1].split(/\s+/);
    
    const total = parseInt(memInfo[1]);
    const used = parseInt(memInfo[2]);
    const free = parseInt(memInfo[3]);
    
    return {
      total,
      used,
      free,
      usage: (used / total) * 100
    };
  } catch (error) {
    console.error('Error getting memory info:', error);
    return {
      total: 0,
      used: 0,
      free: 0,
      usage: 0
    };
  }
}

async function getDiskInfo() {
  try {
    const { stdout } = await execAsync('df -B1 /', { maxBuffer: 1024 * 1024 });
    const lines = stdout.split('\n');
    const diskInfo = lines[1].split(/\s+/);
    
    const total = parseInt(diskInfo[1]);
    const used = parseInt(diskInfo[2]);
    const free = parseInt(diskInfo[3]);
    
    return {
      total,
      used,
      free,
      usage: (used / total) * 100
    };
  } catch (error) {
    console.error('Error getting disk info:', error);
    return {
      total: 0,
      used: 0,
      free: 0,
      usage: 0
    };
  }
}

async function getMagentoInfo(site: Site) {
  try {
    // 获取 Magento 模式
    const { stdout: modeStdout } = await execAsync(`cd ${site.path} && bin/magento deploy:mode:show`);
    const mode = modeStdout.trim();

    // 获取缓存状态
    const { stdout: cacheStdout } = await execAsync(`cd ${site.path} && bin/magento cache:status`);
    const enabledCaches = cacheStdout.split('\n').filter(line => line.includes('ENABLED')).length;
    const totalCaches = cacheStdout.split('\n').filter(line => line.trim()).length;

    // 获取今日订单数（示例查询）
    const { stdout: ordersStdout } = await execAsync(`
      mysql -N -e "
        SELECT COUNT(*) 
        FROM sales_order 
        WHERE created_at >= CURDATE() 
        AND store_id = 1
      " magento
    `);
    const todayOrders = parseInt(ordersStdout.trim()) || 0;

    // 获取活跃用户数（示例查询）
    const { stdout: usersStdout } = await execAsync(`
      mysql -N -e "
        SELECT COUNT(DISTINCT customer_id) 
        FROM customer_visitor 
        WHERE last_visit_at >= DATE_SUB(NOW(), INTERVAL 15 MINUTE)
      " magento
    `);
    const activeUsers = parseInt(usersStdout.trim()) || 0;

    return {
      mode,
      cacheStatus: {
        enabled: enabledCaches,
        total: totalCaches
      },
      orders: {
        today: todayOrders
      },
      activeUsers
    };
  } catch (error) {
    console.error(`Error getting Magento info for ${site.name}:`, error);
    return {
      mode: 'unknown',
      cacheStatus: {
        enabled: 0,
        total: 0
      },
      orders: {
        today: 0
      },
      activeUsers: 0
    };
  }
}

async function getServicesStatus() {
  const services = [
    'nginx',
    'php8.2-fpm',
    'mysql',
    'redis-server',
    'rabbitmq-server',
    'varnish',
    'opensearch',
    'memcached'
  ];

  const statuses: { [key: string]: { status: 'running' | 'stopped' | 'error'; error?: string } } = {};

  for (const service of services) {
    try {
      const { stdout } = await execAsync(`systemctl is-active ${service}`);
      statuses[service] = {
        status: stdout.trim() === 'active' ? 'running' : 'stopped'
      };
    } catch (error) {
      console.error(`Error checking ${service} status:`, error);
      statuses[service] = {
        status: 'error',
        error: 'Service check failed'
      };
    }
  }

  return statuses;
}

export async function GET() {
  try {
    // 读取站点配置
    const sitesData = await fs.readFile(SITES_CONFIG_PATH, 'utf-8');
    const { sites } = JSON.parse(sitesData);
    const enabledSites = sites.filter((site: Site) => site.enabled);

    // 并行获取所有信息
    const [uptime, cpuUsage, memoryInfo, diskInfo, servicesStatus] = await Promise.all([
      getUptime(),
      getCpuUsage(),
      getMemoryInfo(),
      getDiskInfo(),
      getServicesStatus()
    ]);

    // 并行获取所有站点的 Magento 信息
    const siteStatuses = await Promise.all(
      enabledSites.map(async (site: Site) => {
        const status = await getMagentoInfo(site);
        return {
          id: site.id,
          name: site.name,
          path: site.path,
          status
        };
      })
    );

    // 转换为以 ID 为键的对象
    const sitesObject = siteStatuses.reduce((acc, site) => {
      acc[site.id] = {
        name: site.name,
        path: site.path,
        status: site.status
      };
      return acc;
    }, {} as SystemStatus['sites']);

    const systemStatus: SystemStatus = {
      uptime,
      cpu: {
        usage: cpuUsage
      },
      memory: memoryInfo,
      disk: diskInfo,
      sites: sitesObject,
      services: servicesStatus
    };

    return NextResponse.json(systemStatus);
  } catch (error) {
    console.error('Error getting system status:', error);
    return NextResponse.json(
      { error: 'Failed to get system status' },
      { status: 500 }
    );
  }
} 