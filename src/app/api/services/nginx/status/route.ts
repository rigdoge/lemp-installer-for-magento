import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function GET() {
    try {
        console.log('Checking Nginx status...');
        
        // 使用 systemctl 检查 Nginx 状态
        const { stdout } = await execAsync('systemctl is-active nginx', { shell: '/bin/bash' });
        const status = stdout.trim();
        
        console.log('Nginx status:', status);
        
        return NextResponse.json({
            isRunning: status === 'active',
            metrics: {
                status: status
            }
        });
    } catch (error) {
        console.error('Error checking Nginx status:', error);
        return NextResponse.json(
            { error: error instanceof Error ? error.message : 'Failed to check Nginx status' },
            { status: 500 }
        );
    }
}