import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

async function checkAlertmanager(url: string): Promise<boolean> {
  try {
    const response = await fetch(`${url}/-/healthy`);
    return response.ok;
  } catch (error) {
    return false;
  }
}

export async function GET() {
  try {
    const alertmanagerUrl = process.env.NEXT_PUBLIC_ALERTMANAGER_URL || 'http://localhost:9093';
    const isRunning = await checkAlertmanager(alertmanagerUrl);

    return NextResponse.json({
      running: isRunning,
      error: !isRunning ? 'Service not accessible' : undefined
    });
  } catch (error) {
    console.error('Error checking Alertmanager status:', error);
    return NextResponse.json(
      { error: 'Failed to check Alertmanager status' },
      { status: 500 }
    );
  }
} 