import { NextResponse } from 'next/server';
import { headers } from 'next/headers';

// 注意: 这个 API 路由使用了 headers() API，这会导致 Next.js 在构建时显示
// "Dynamic server usage" 警告。这是预期的行为，因为我们需要在服务器端
// 实时检查监控服务的状态。这个警告可以安全地忽略。

async function checkEndpoint(url: string): Promise<boolean> {
  try {
    const response = await fetch(url, { 
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    });
    return response.ok;
  } catch (error) {
    return false;
  }
}

export async function GET() {
  try {
    const headersList = headers();
    const protocol = headersList.get('x-forwarded-proto') || 'http';
    const host = headersList.get('host') || 'localhost';
    const baseUrl = `${protocol}://${host.split(':')[0]}`;

    const prometheusUrl = process.env.NEXT_PUBLIC_PROMETHEUS_URL || `${baseUrl}:9090`;
    const alertmanagerUrl = process.env.NEXT_PUBLIC_ALERTMANAGER_URL || `${baseUrl}:9093`;
    const grafanaUrl = process.env.NEXT_PUBLIC_GRAFANA_URL || `${baseUrl}:3000`;

    const [prometheusRunning, alertmanagerRunning, grafanaRunning] = await Promise.all([
      checkEndpoint(`${prometheusUrl}/-/healthy`),
      checkEndpoint(`${alertmanagerUrl}/-/healthy`),
      checkEndpoint(`${grafanaUrl}/api/health`)
    ]);

    return NextResponse.json({
      prometheus: {
        running: prometheusRunning,
        error: !prometheusRunning ? 'Service not accessible' : undefined
      },
      alertmanager: {
        running: alertmanagerRunning,
        error: !alertmanagerRunning ? 'Service not accessible' : undefined
      },
      grafana: {
        running: grafanaRunning,
        error: !grafanaRunning ? 'Service not accessible' : undefined
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