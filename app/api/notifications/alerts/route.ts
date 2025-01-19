import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const alertmanagerUrl = process.env.NEXT_PUBLIC_ALERTMANAGER_URL || 'http://localhost:9093';
    const response = await fetch(`${alertmanagerUrl}/api/v2/alerts`);
    
    if (!response.ok) {
      throw new Error('Failed to fetch alerts from Alertmanager');
    }

    const alerts = await response.json();
    return NextResponse.json(alerts);
  } catch (error) {
    console.error('Error fetching alerts:', error);
    return NextResponse.json(
      { error: 'Failed to fetch alerts' },
      { status: 500 }
    );
  }
} 