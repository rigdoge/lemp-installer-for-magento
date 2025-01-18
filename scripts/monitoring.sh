#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本"
  exit 1
fi

# 定义服务列表
SERVICES=("prometheus" "alertmanager" "grafana-server" "node_exporter")

# 显示帮助信息
show_help() {
  echo "用法: $0 [命令]"
  echo "命令:"
  echo "  status    - 查看所有监控服务状态"
  echo "  start     - 启动所有监控服务"
  echo "  stop      - 停止所有监控服务"
  echo "  restart   - 重启所有监控服务"
  echo "  ports     - 查看端口监听状态"
  echo "  urls      - 显示访问地址"
}

# 检查服务状态
check_status() {
  echo "=== 服务状态 ==="
  for service in "${SERVICES[@]}"; do
    status=$(systemctl is-active "$service")
    if [ "$status" = "active" ]; then
      echo "✅ $service: 运行中"
    else
      echo "❌ $service: 未运行"
    fi
  done
}

# 检查端口状态
check_ports() {
  echo "=== 端口状态 ==="
  echo "Prometheus (9090):"
  netstat -tuln | grep ":9090 "
  echo "Alertmanager (9093):"
  netstat -tuln | grep ":9093 "
  echo "Grafana (3000):"
  netstat -tuln | grep ":3000 "
  echo "Node Exporter (9100):"
  netstat -tuln | grep ":9100 "
}

# 启动服务
start_services() {
  echo "正在启动监控服务..."
  for service in "${SERVICES[@]}"; do
    echo "启动 $service..."
    systemctl start "$service"
  done
  check_status
}

# 停止服务
stop_services() {
  echo "正在停止监控服务..."
  for service in "${SERVICES[@]}"; do
    echo "停止 $service..."
    systemctl stop "$service"
  done
  check_status
}

# 重启服务
restart_services() {
  echo "正在重启监控服务..."
  for service in "${SERVICES[@]}"; do
    echo "重启 $service..."
    systemctl restart "$service"
  done
  check_status
}

# 显示访问地址
show_urls() {
  echo "=== 访问地址 ==="
  echo "Prometheus:   http://localhost:9090"
  echo "Alertmanager: http://localhost:9093"
  echo "Grafana:      http://localhost:3000"
  echo "Node Exporter: http://localhost:9100/metrics"
  echo ""
  echo "Grafana 默认登录凭据："
  echo "用户名: admin"
  echo "密码: admin"
}

# 主函数
case "$1" in
  "status")
    check_status
    ;;
  "start")
    start_services
    ;;
  "stop")
    stop_services
    ;;
  "restart")
    restart_services
    ;;
  "ports")
    check_ports
    ;;
  "urls")
    show_urls
    ;;
  *)
    show_help
    ;;
esac 