import { NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

const SITES_CONFIG_PATH = path.join(process.cwd(), 'config', 'sites.json');

export interface Site {
  id: string;
  name: string;
  path: string;
  enabled: boolean;
  frontendUrl?: string;  // 前台 URL
  adminUrl?: string;     // 后台 URL
}

// 确保配置目录和文件存在
async function ensureConfigFile() {
  try {
    await fs.mkdir(path.join(process.cwd(), 'config'), { recursive: true });
    try {
      await fs.access(SITES_CONFIG_PATH);
    } catch {
      await fs.writeFile(SITES_CONFIG_PATH, JSON.stringify({ sites: [] }, null, 2));
    }
  } catch (error) {
    console.error('Error ensuring config file:', error);
    throw error;
  }
}

// 获取所有站点
export async function GET() {
  try {
    await ensureConfigFile();
    const data = await fs.readFile(SITES_CONFIG_PATH, 'utf-8');
    const config = JSON.parse(data);
    return NextResponse.json(config.sites);
  } catch (error) {
    console.error('Error reading sites:', error);
    return NextResponse.json(
      { error: 'Failed to get sites' },
      { status: 500 }
    );
  }
}

// 添加或更新站点
export async function POST(request: Request) {
  try {
    await ensureConfigFile();
    const site = await request.json();
    
    // 验证必需字段
    if (!site.name || !site.path) {
      return NextResponse.json(
        { error: 'Name and path are required' },
        { status: 400 }
      );
    }

    const data = await fs.readFile(SITES_CONFIG_PATH, 'utf-8');
    const config = JSON.parse(data);
    
    if (!site.id) {
      // 新站点
      site.id = Date.now().toString();
      site.enabled = true;
      site.frontendUrl = site.frontendUrl || '';
      site.adminUrl = site.adminUrl || '';
      config.sites.push(site);
    } else {
      // 更新现有站点
      const index = config.sites.findIndex((s: Site) => s.id === site.id);
      if (index === -1) {
        return NextResponse.json(
          { error: 'Site not found' },
          { status: 404 }
        );
      }
      config.sites[index] = { 
        ...config.sites[index], 
        ...site,
        frontendUrl: site.frontendUrl || config.sites[index].frontendUrl || '',
        adminUrl: site.adminUrl || config.sites[index].adminUrl || ''
      };
    }

    await fs.writeFile(SITES_CONFIG_PATH, JSON.stringify(config, null, 2));
    return NextResponse.json(site);
  } catch (error) {
    console.error('Error saving site:', error);
    return NextResponse.json(
      { error: 'Failed to save site' },
      { status: 500 }
    );
  }
}

// 删除站点
export async function DELETE(request: Request) {
  try {
    const { id } = await request.json();
    if (!id) {
      return NextResponse.json(
        { error: 'Site ID is required' },
        { status: 400 }
      );
    }

    const data = await fs.readFile(SITES_CONFIG_PATH, 'utf-8');
    const config = JSON.parse(data);
    
    const index = config.sites.findIndex((site: Site) => site.id === id);
    if (index === -1) {
      return NextResponse.json(
        { error: 'Site not found' },
        { status: 404 }
      );
    }

    config.sites.splice(index, 1);
    await fs.writeFile(SITES_CONFIG_PATH, JSON.stringify(config, null, 2));
    
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting site:', error);
    return NextResponse.json(
      { error: 'Failed to delete site' },
      { status: 500 }
    );
  }
}

export const dynamic = 'force-dynamic';
export const revalidate = 0; 