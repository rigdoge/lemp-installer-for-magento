import { useState, useEffect } from 'react';
import { ServiceStatus } from '../types/monitoring';

export function useServiceMonitor(serviceName: string) {
    const [status, setStatus] = useState<ServiceStatus | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStatus = async () => {
            try {
                const response = await fetch(`/api/services/${serviceName}/status`);
                if (!response.ok) {
                    throw new Error('Failed to fetch service status');
                }
                const data = await response.json();
                setStatus(data);
                setError(null);
            } catch (err) {
                setError(err instanceof Error ? err.message : 'Unknown error');
                setStatus(null);
            } finally {
                setLoading(false);
            }
        };

        fetchStatus();
        const interval = setInterval(fetchStatus, 5000); // Poll every 5 seconds

        return () => clearInterval(interval);
    }, [serviceName]);

    return { status, error, loading };
} 