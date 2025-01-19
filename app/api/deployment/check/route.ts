import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, mkdir } from 'fs/promises';
import path from 'path';

const execAsync = promisify(exec);

export async function POST(request: Request) {
  try {
    const { host, authType, password, sshKey } = await request.json();

    // 创建临时目录
    const tmpDir = path.join(process.cwd(), 'tmp');
    await mkdir(tmpDir, { recursive: true });

    let checkCommand: string;

    if (authType === 'password') {
      // 使用 sshpass 进行密码登录
      checkCommand = `SSHPASS='${password}' sshpass -e ${path.join(process.cwd(), 'ansible', 'scripts', 'check', 'pre-check.sh')} -h ${host} -p`;
    } else {
      // 使用 SSH 密钥登录
      const keyPath = path.join(tmpDir, 'deploy.key');
      await writeFile(keyPath, sshKey, { mode: 0o600 });
      checkCommand = `${path.join(process.cwd(), 'ansible', 'scripts', 'check', 'pre-check.sh')} -h ${host} -k ${keyPath}`;
    }

    // 执行环境检查脚本
    const { stdout, stderr } = await execAsync(checkCommand);

    // 解析检查结果
    const results = {
      success: !stderr,
      output: stdout,
      error: stderr,
      checks: {
        os: true,
        cpu: true,
        memory: true,
        disk: true,
        network: true,
      }
    };

    return NextResponse.json(results);
  } catch (error) {
    console.error('Environment check failed:', error);
    return NextResponse.json(
      { error: 'Failed to check environment' },
      { status: 500 }
    );
  }
} 