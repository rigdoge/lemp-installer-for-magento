module.exports = {
  apps: [{
    name: 'lemp-manager',
    script: 'npm',
    args: 'start',
    cwd: '/opt/lemp-manager',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    exec_mode: 'fork',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    exp_backoff_restart_delay: 100
  }]
} 