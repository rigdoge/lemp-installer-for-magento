import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, mkdir } from 'fs/promises';
import path from 'path';

const execAsync = promisify(exec);

export async function POST(request: Request) {
  try {
    const config = await request.json();
    
    // 创建临时目录
    const tmpDir = path.join(process.cwd(), 'tmp');
    await mkdir(tmpDir, { recursive: true });

    // 生成临时的 inventory 文件
    const inventoryContent = `
[webservers]
${config.host}

[webservers:vars]
ansible_ssh_private_key_file=${path.join(tmpDir, 'deploy.key')}
ansible_python_interpreter=/usr/bin/python3
    `.trim();

    const inventoryPath = path.join(tmpDir, 'inventory.ini');
    await writeFile(inventoryPath, inventoryContent);

    // 生成临时的变量文件
    const varsContent = `
---
nginx_version: "${config.versions.nginx}"
php_version: "${config.versions.php}"
mysql_version: "${config.versions.mysql}"
redis_version: "${config.versions.redis}"
varnish_version: "${config.versions.varnish}"
opensearch_version: "${config.versions.opensearch}"
rabbitmq_version: "${config.versions.rabbitmq}"

# 组件启用状态
nginx_enabled: ${config.components.nginx}
php_enabled: ${config.components.php}
mysql_enabled: ${config.components.mysql}
redis_enabled: ${config.components.redis}
varnish_enabled: ${config.components.varnish}
opensearch_enabled: ${config.components.opensearch}
rabbitmq_enabled: ${config.components.rabbitmq}
    `.trim();

    const varsPath = path.join(tmpDir, 'vars.yml');
    await writeFile(varsPath, varsContent);

    // 执行安装脚本
    const installScript = path.join(process.cwd(), 'src', 'scripts', 'install', 'install.sh');
    const { stdout, stderr } = await execAsync(
      `${installScript} -i ${inventoryPath} -v ${varsPath}`
    );

    return NextResponse.json({
      success: !stderr,
      output: stdout,
      error: stderr
    });
  } catch (error) {
    console.error('Installation failed:', error);
    return NextResponse.json(
      { error: 'Failed to install components' },
      { status: 500 }
    );
  }
} 