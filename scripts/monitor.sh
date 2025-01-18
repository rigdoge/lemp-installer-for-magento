#!/bin/bash

# 设置错误时退出
set -e

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 定义版本和目录
PROMETHEUS_VERSION="2.45.0"
NODE_EXPORTER_VERSION="1.6.1"
NGINX_EXPORTER_VERSION="0.11.0"
ALERTMANAGER_VERSION="0.26.0"

MONITOR_DIR="/opt/monitoring"
CONFIG_DIR="/etc/monitoring"
LOG_DIR="/var/log/monitoring"

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用 root 用户运行此脚本${NC}"
        exit 1
    fi
}

# 创建必要的目录
create_directories() {
    mkdir -p "$MONITOR_DIR"/{prometheus,alertmanager,exporters}
    mkdir -p "$CONFIG_DIR"/{prometheus,alertmanager}
    mkdir -p "$LOG_DIR"
}

# 安装 Nginx Exporter
install_nginx_exporter() {
    echo -e "${GREEN}安装 Nginx Exporter...${NC}"
    cd "$MONITOR_DIR/exporters"
    
    # 下载并解压 nginx-prometheus-exporter
    wget "https://github.com/nginx/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VERSION}/nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz"
    tar xzf "nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz"
    mv nginx-prometheus-exporter /usr/local/bin/
    rm "nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz"

    # 创建 systemd 服务
    cat > /etc/systemd/system/nginx-exporter.service << EOF
[Unit]
Description=Nginx Prometheus Exporter
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/nginx-prometheus-exporter \\
    --nginx.scrape-uri=http://localhost/nginx_status \\
    --web.listen-address=:9113

[Install]
WantedBy=multi-user.target
EOF
}

# 安装 Prometheus
install_prometheus() {
    echo -e "${GREEN}安装 Prometheus...${NC}"
    cd "$MONITOR_DIR"
    
    # 下载并解压 Prometheus
    wget "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
    tar xzf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
    mv "prometheus-${PROMETHEUS_VERSION}.linux-amd64" prometheus
    rm "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

    # 创建 Prometheus 配置
    cat > "$CONFIG_DIR/prometheus/prometheus.yml" << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:9113']
EOF

    # 创建告警规则
    mkdir -p "$CONFIG_DIR/prometheus/rules"
    cat > "$CONFIG_DIR/prometheus/rules/nginx.yml" << EOF
groups:
- name: nginx
  rules:
  - alert: NginxDown
    expr: nginx_up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Nginx 服务已停止"
      description: "服务器 {{ \$labels.instance }} 的 Nginx 服务已停止运行"

  - alert: NginxHighHttp5xxRate
    expr: rate(nginx_http_requests_total{status=~"^5.."}[5m]) > 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Nginx 5xx 错误率过高"
      description: "服务器 {{ \$labels.instance }} 的 5xx 错误率超过每秒 1 个"

  - alert: NginxHighConnections
    expr: nginx_connections_current > 1000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Nginx 连接数过高"
      description: "服务器 {{ \$labels.instance }} 的当前连接数超过 1000"
EOF

    # 创建 systemd 服务
    cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=$MONITOR_DIR/prometheus/prometheus \\
    --config.file=$CONFIG_DIR/prometheus/prometheus.yml \\
    --storage.tsdb.path=$MONITOR_DIR/prometheus/data \\
    --web.console.templates=$MONITOR_DIR/prometheus/consoles \\
    --web.console.libraries=$MONITOR_DIR/prometheus/console_libraries \\
    --web.listen-address=:9090

[Install]
WantedBy=multi-user.target
EOF
}

# 安装 Alertmanager
install_alertmanager() {
    echo -e "${GREEN}安装 Alertmanager...${NC}"
    cd "$MONITOR_DIR"
    
    # 下载并解压 Alertmanager
    wget "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"
    tar xzf "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"
    mv "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64" alertmanager
    rm "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"

    # 创建 Alertmanager 配置
    cat > "$CONFIG_DIR/alertmanager/alertmanager.yml" << EOF
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'telegram'

receivers:
- name: 'telegram'
  telegram_configs:
  - bot_token: 'YOUR_BOT_TOKEN'
    chat_id: YOUR_CHAT_ID
    parse_mode: 'HTML'
    message: |-
      🚨 <b>{{ .Status | toUpper }}</b>
      <b>告警名称:</b> {{ .CommonAnnotations.summary }}
      <b>详细信息:</b> {{ .CommonAnnotations.description }}
      <b>开始时间:</b> {{ .StartsAt.Format "2006-01-02 15:04:05" }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname']
EOF

    # 创建 systemd 服务
    cat > /etc/systemd/system/alertmanager.service << EOF
[Unit]
Description=Alertmanager
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=$MONITOR_DIR/alertmanager/alertmanager \\
    --config.file=$CONFIG_DIR/alertmanager/alertmanager.yml \\
    --storage.path=$MONITOR_DIR/alertmanager/data \\
    --web.listen-address=:9093

[Install]
WantedBy=multi-user.target
EOF
}

# 配置 Nginx
configure_nginx() {
    echo -e "${GREEN}配置 Nginx...${NC}"
    
    # 添加 status 配置
    cat > /etc/nginx/conf.d/status.conf << EOF
server {
    listen 127.0.0.1:80;
    server_name localhost;

    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

    # 测试配置并重启 Nginx
    nginx -t && systemctl restart nginx
}

# 创建系统用户
create_user() {
    echo -e "${GREEN}创建系统用户...${NC}"
    
    # 创建 prometheus 用户
    if ! id "prometheus" &>/dev/null; then
        useradd --system --no-create-home --shell /bin/false prometheus
    fi

    # 设置目录权限
    chown -R prometheus:prometheus "$MONITOR_DIR"
    chown -R prometheus:prometheus "$CONFIG_DIR"
    chown -R prometheus:prometheus "$LOG_DIR"
}

# 配置 Telegram Bot
configure_telegram() {
    echo -e "${GREEN}配置 Telegram Bot...${NC}"
    
    # 从配置文件读取 Token 和 Chat ID
    if [ -f "$CONFIG_DIR/telegram.conf" ]; then
        source "$CONFIG_DIR/telegram.conf"
        if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
            # 更新 Alertmanager 配置
            sed -i "s/YOUR_BOT_TOKEN/${BOT_TOKEN}/" "$CONFIG_DIR/alertmanager/alertmanager.yml"
            sed -i "s/YOUR_CHAT_ID/${CHAT_ID}/" "$CONFIG_DIR/alertmanager/alertmanager.yml"
            systemctl restart alertmanager
        fi
    fi
}

# 启动服务
start_services() {
    echo -e "${GREEN}启动服务...${NC}"
    
    systemctl daemon-reload
    
    systemctl enable nginx-exporter
    systemctl enable prometheus
    systemctl enable alertmanager
    
    systemctl start nginx-exporter
    systemctl start prometheus
    systemctl start alertmanager
}

# 安装监控系统
install_monitor() {
    check_root
    create_directories
    create_user
    install_nginx_exporter
    install_prometheus
    install_alertmanager
    configure_nginx
    start_services
    
    echo -e "${GREEN}安装完成!${NC}"
    echo -e "Prometheus 地址: http://your-server-ip:9090"
    echo -e "Alertmanager 地址: http://your-server-ip:9093"
}

# 卸载监控系统
uninstall_monitor() {
    check_root
    
    systemctl stop nginx-exporter prometheus alertmanager
    systemctl disable nginx-exporter prometheus alertmanager
    
    rm -f /etc/systemd/system/nginx-exporter.service
    rm -f /etc/systemd/system/prometheus.service
    rm -f /etc/systemd/system/alertmanager.service
    
    rm -rf "$MONITOR_DIR"
    rm -rf "$CONFIG_DIR"
    rm -rf "$LOG_DIR"
    
    systemctl daemon-reload
    
    echo -e "${GREEN}卸载完成${NC}"
}

# 更新 Telegram 配置
update_telegram() {
    check_root
    if [ -z "$2" ] || [ -z "$3" ]; then
        echo "用法: $0 update-telegram <bot_token> <chat_id>"
        exit 1
    fi
    
    # 保存配置到文件
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/telegram.conf" << EOF
BOT_TOKEN="$2"
CHAT_ID="$3"
EOF
    
    # 应用配置
    configure_telegram
    
    echo -e "${GREEN}Telegram 配置已更新${NC}"
}

# 主函数
main() {
    case "$1" in
        install)
            install_monitor
            ;;
        uninstall)
            uninstall_monitor
            ;;
        update-telegram)
            update_telegram "$@"
            ;;
        *)
            echo "用法: $0 {install|uninstall|update-telegram <bot_token> <chat_id>}"
            exit 1
            ;;
    esac
}

main "$@" 