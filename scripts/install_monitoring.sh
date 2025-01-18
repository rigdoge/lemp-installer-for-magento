#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本"
  exit 1
fi

# 获取系统类型
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "无法确定操作系统类型"
  exit 1
fi

# 设置安装目录
INSTALL_DIR="/opt/monitoring"
CONFIG_DIR="/etc/lemp-manager/monitoring"
DATA_DIR="/var/lib/lemp-manager/monitoring"

# 创建必要的目录
create_directories() {
  mkdir -p "$INSTALL_DIR"
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$DATA_DIR"
  mkdir -p "$DATA_DIR/prometheus"
  mkdir -p "$DATA_DIR/grafana"
}

# 下载并安装 Prometheus
install_prometheus() {
  echo "正在安装 Prometheus..."
  
  # 使用稳定版本的 Prometheus，并指定 ARM64 架构
  PROMETHEUS_VERSION="2.45.0"
  ARCH="arm64"
  wget "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.darwin-${ARCH}.tar.gz"
  tar xzf "prometheus-${PROMETHEUS_VERSION}.darwin-${ARCH}.tar.gz"
  cp "prometheus-${PROMETHEUS_VERSION}.darwin-${ARCH}/prometheus" /usr/local/bin/
  cp "prometheus-${PROMETHEUS_VERSION}.darwin-${ARCH}/promtool" /usr/local/bin/
  
  # 创建 Prometheus 配置文件
  cat > "$CONFIG_DIR/prometheus.yml" << EOL
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:9113']
EOL

  # 创建 systemd 服务
  cat > /etc/systemd/system/prometheus.service << EOL
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=$CONFIG_DIR/prometheus.yml \
    --storage.tsdb.path=$DATA_DIR/prometheus \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=:9090

[Install]
WantedBy=multi-user.target
EOL

  # 创建用户和组
  useradd --no-create-home --shell /bin/false prometheus || true
  chown -R prometheus:prometheus "$DATA_DIR/prometheus"
  chown -R prometheus:prometheus "$CONFIG_DIR"
  chmod 755 /usr/local/bin/prometheus
  chmod 755 /usr/local/bin/promtool
  
  # 启动服务
  systemctl daemon-reload
  systemctl enable prometheus
  systemctl start prometheus
}

# 下载并安装 Alertmanager
install_alertmanager() {
  echo "正在安装 Alertmanager..."
  
  # 使用稳定版本的 Alertmanager，并指定 ARM64 架构
  ALERTMANAGER_VERSION="0.26.0"
  ARCH="arm64"
  wget "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.darwin-${ARCH}.tar.gz"
  tar xzf "alertmanager-${ALERTMANAGER_VERSION}.darwin-${ARCH}.tar.gz"
  cp "alertmanager-${ALERTMANAGER_VERSION}.darwin-${ARCH}/alertmanager" /usr/local/bin/
  
  # 创建 Alertmanager 配置文件
  cat > "$CONFIG_DIR/alertmanager.yml" << EOL
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
  - bot_token: ''
    chat_id: 0
    parse_mode: 'HTML'
EOL

  # 创建 systemd 服务
  cat > /etc/systemd/system/alertmanager.service << EOL
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file=$CONFIG_DIR/alertmanager.yml \
    --storage.path=$DATA_DIR/alertmanager \
    --web.listen-address=:9093

[Install]
WantedBy=multi-user.target
EOL

  # 创建用户和组
  useradd --no-create-home --shell /bin/false alertmanager || true
  mkdir -p "$DATA_DIR/alertmanager"
  chown -R alertmanager:alertmanager "$DATA_DIR/alertmanager"
  chown -R alertmanager:alertmanager "$CONFIG_DIR/alertmanager.yml"
  chmod 755 /usr/local/bin/alertmanager
  
  # 启动服务
  systemctl daemon-reload
  systemctl enable alertmanager
  systemctl start alertmanager
}

# 安装 Grafana
install_grafana() {
  echo "正在安装 Grafana..."
  
  if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    # 添加 Grafana 仓库
    apt-get install -y apt-transport-https software-properties-common
    wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
    echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
    apt-get update
    apt-get install -y grafana
  elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    # 添加 Grafana 仓库
    cat > /etc/yum.repos.d/grafana.repo << EOL
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOL
    yum install -y grafana
  else
    echo "不支持的操作系统"
    exit 1
  fi

  # 配置 Grafana
  mkdir -p "$DATA_DIR/grafana"
  chown -R grafana:grafana "$DATA_DIR/grafana"
  
  # 修改 Grafana 配置
  sed -i "s|;data = /var/lib/grafana|data = $DATA_DIR/grafana|" /etc/grafana/grafana.ini
  
  # 启动服务
  systemctl daemon-reload
  systemctl enable grafana-server
  systemctl start grafana-server
}

# 安装 Node Exporter
install_node_exporter() {
  echo "正在安装 Node Exporter..."
  
  # 使用稳定版本的 Node Exporter，并指定 ARM64 架构
  NODE_EXPORTER_VERSION="1.7.0"
  ARCH="arm64"
  wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.darwin-${ARCH}.tar.gz"
  tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.darwin-${ARCH}.tar.gz"
  cp "node_exporter-${NODE_EXPORTER_VERSION}.darwin-${ARCH}/node_exporter" /usr/local/bin/
  
  # 创建 systemd 服务
  cat > /etc/systemd/system/node_exporter.service << EOL
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOL

  # 创建用户和组
  useradd --no-create-home --shell /bin/false node_exporter || true
  chmod 755 /usr/local/bin/node_exporter
  
  # 启动服务
  systemctl daemon-reload
  systemctl enable node_exporter
  systemctl start node_exporter
}

# 清理下载的文件
cleanup() {
  rm -rf "prometheus-"*
  rm -rf "alertmanager-"*
  rm -rf "node_exporter-"*
}

# 主函数
main() {
  echo "开始安装监控服务..."
  
  create_directories
  install_prometheus
  install_alertmanager
  install_grafana
  install_node_exporter
  cleanup
  
  echo "监控服务安装完成！"
  echo "Prometheus: http://localhost:9090"
  echo "Alertmanager: http://localhost:9093"
  echo "Grafana: http://localhost:3000"
  echo "默认 Grafana 登录凭据："
  echo "用户名: admin"
  echo "密码: admin"
}

# 运行主函数
main 