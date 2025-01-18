# Installation Guide

This guide provides detailed instructions for installing and configuring the LEMP Stack Manager for Magento.

## Prerequisites

Before installation, ensure your system meets the following requirements:

- Ubuntu 20.04 or later
- Root access or sudo privileges
- Minimum 2GB RAM (4GB recommended for production)
- 20GB free disk space
- Open ports: 80, 443, 3001 (for web dashboard)

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/lemp-installer-for-magento.git
cd lemp-installer-for-magento
```

### 2. Run Installation Script

```bash
./scripts/panel.sh install
```

The installation script will:
1. Install required system packages
2. Set up Nginx, PHP-FPM, Percona Server 8.0, and Redis
3. Configure services for optimal performance
4. Install and configure the web dashboard
5. Set up the monitoring system

### 3. Verify Installation

After installation completes:

1. Check service status:
```bash
./scripts/panel.sh status
```

2. Access the web dashboard:
```
http://your-server-ip:3001
```

## Configuration

### Service Configuration

Each service can be configured through the web dashboard or using the panel script:

```bash
# Start a service
./scripts/panel.sh start <service>

# Stop a service
./scripts/panel.sh stop <service>

# Restart a service
./scripts/panel.sh restart <service>

# Check service status
./scripts/panel.sh status <service>
```

Available services: nginx, php-fpm, percona, redis

### Monitoring Configuration

The monitoring system is configured to track:
- Service status
- Resource usage (CPU, Memory, Disk)
- Error logs
- Performance metrics

Configure notification settings in the web dashboard for:
- Service status changes
- Resource usage thresholds
- Error alerts

## Troubleshooting

### Common Issues

1. **Web Dashboard Not Accessible**
   - Check if the service is running: `systemctl status lemp-panel`
   - Verify port 3001 is open: `netstat -tulpn | grep 3001`
   - Check logs: `journalctl -u lemp-panel`

2. **Service Status Errors**
   - Verify service installation: `which <service>`
   - Check service logs in `/var/log/<service>`
   - Ensure proper permissions

3. **Permission Issues**
   - Verify user permissions
   - Check file ownership
   - Review system logs

### Logs

Important log locations:
- Installation logs: `/var/log/lemp-installer/install.log`
- Panel logs: `/var/log/lemp-panel/panel.log`
- Service logs: `/var/log/lemp-panel/services.log`

## Uninstallation

To remove the LEMP Stack Manager:

```bash
./scripts/panel.sh uninstall
```

This will:
1. Stop all managed services
2. Remove configuration files
3. Uninstall the web dashboard
4. Clean up system changes

Note: This will not remove your data or service configurations.
