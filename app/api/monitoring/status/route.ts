import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function checkService(service: string): Promise<boolean> {
  try {
    const { stdout } = await execAsync(`systemctl is-active ${service}`);
    return stdout.trim() === 'active';
  } catch (error) {
    return false;
  }
}

async function checkPort(port: number): Promise<boolean> {
  try {
    const { stdout } = await execAsync(`lsof -i:${port} -P -n | grep LISTEN`);
    return stdout.trim().length > 0;
  } catch (error) {
    return false;
  }
}

export async function GET() {
  try {
    const prometheusRunning = await checkService('prometheus');
    const alertmanagerRunning = await checkService('alertmanager');
    const grafanaRunning = await checkService('grafana-server');

    const prometheusPortOpen = await checkPort(9090);
    const alertmanagerPortOpen = await checkPort(9093);
    const grafanaPortOpen = await checkPort(3000);

    return NextResponse.json({
      prometheus: {
        running: prometheusRunning && prometheusPortOpen,
        error: !prometheusRunning ? 'Service not running' : 
               !prometheusPortOpen ? 'Port 9090 not accessible' : undefined
      },
      alertmanager: {
        running: alertmanagerRunning && alertmanagerPortOpen,
        error: !alertmanagerRunning ? 'Service not running' : 
               !alertmanagerPortOpen ? 'Port 9093 not accessible' : undefined
      },
      grafana: {
        running: grafanaRunning && grafanaPortOpen,
        error: !grafanaRunning ? 'Service not running' : 
               !grafanaPortOpen ? 'Port 3000 not accessible' : undefined
      }
    });
  } catch (error) {
    console.error('Error checking monitoring status:', error);
    return NextResponse.json(
      { error: 'Failed to check monitoring status' },
      { status: 500 }
    );
  }
} 