# LEMP Stack Manager for Magento

A comprehensive tool for installing, configuring, and managing LEMP (Linux, Nginx, Percona, PHP) stack optimized for Magento.

## Features

- **One-Click Installation**: Automated LEMP stack setup optimized for Magento
- **Service Management**: Easy control of Nginx, PHP-FPM, Percona, and Redis services
- **Configuration Management**: Pre-configured templates and easy customization
- **Monitoring System**: Real-time monitoring of services and system resources
- **Web Dashboard**: Modern web interface for system management
- **Notification System**: Alerts via Telegram and email

## Requirements

- Ubuntu 20.04 or later
- Root access or sudo privileges
- Minimum 2GB RAM
- 20GB free disk space

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/lemp-installer-for-magento.git
cd lemp-installer-for-magento
```

2. Run the installation:
```bash
./scripts/panel.sh install
```

3. Access the web dashboard:
```
http://your-server-ip:3001
```

## Documentation

- [Installation Guide](docs/installation.md)
- [Configuration Guide](docs/configuration.md)
- [API Documentation](docs/api.md)

## Directory Structure

```
lemp-installer-for-magento/
├── scripts/          # Installation and management scripts
├── config/           # Configuration templates
├── monitor/          # Monitoring system
├── web/             # Web dashboard
├── tests/           # Test cases
├── logs/            # Log files
└── docs/            # Documentation
```

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
