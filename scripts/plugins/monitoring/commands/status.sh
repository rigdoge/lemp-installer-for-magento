#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 设置目录路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENABLED_DIR="$SCRIPT_DIR/../enabled"

# 检查目录是否存在
if [ ! -d "$ENABLED_DIR" ]; then
    echo -e "${RED}Error: Enabled monitors directory not found${NC}"
    echo "Expected path: $ENABLED_DIR"
    exit 1
fi

echo -e "${GREEN}Monitoring Status:${NC}"
echo "=================="

# 显示调试信息
echo -e "${YELLOW}Debug Info:${NC}"
echo "Script Directory: $SCRIPT_DIR"
echo "Enabled Directory: $ENABLED_DIR"
echo "Enabled Monitors:"
ls -la "$ENABLED_DIR"
echo "==================="

# 检查是否有启用的监控
monitor_count=$(find "$ENABLED_DIR" -type l -name "*.monitor" | wc -l)
if [ "$monitor_count" -eq 0 ]; then
    echo -e "${YELLOW}No monitors are currently enabled${NC}"
    echo "To enable a monitor, use: ./enable.sh <monitor_name>"
    exit 0
fi

# 遍历所有启用的监控
for monitor in "$ENABLED_DIR"/*.monitor; do
    if [ -L "$monitor" ]; then
        name=$(basename "$monitor" .monitor)
        echo -e "\n${GREEN}Monitor: $name${NC}"
        echo "Link target: $(readlink -f "$monitor")"
        
        # 检查监控的状态脚本是否存在并可执行
        status_script="$(readlink -f "$monitor").status"
        echo "Status script: $status_script"
        
        if [ -x "$status_script" ]; then
            # 执行状态检查脚本
            echo "Executing status check..."
            output=$("$status_script")
            exit_code=$?
            
            case $exit_code in
                0)
                    echo -e "Status: ${GREEN}Running${NC}"
                    echo "$output"
                    ;;
                1)
                    echo -e "Status: ${RED}Error${NC}"
                    echo "$output"
                    ;;
                2)
                    echo -e "Status: ${YELLOW}Warning${NC}"
                    echo "$output"
                    ;;
                *)
                    echo -e "Status: ${RED}Unknown (exit code: $exit_code)${NC}"
                    echo "$output"
                    ;;
            esac
        else
            echo -e "${RED}Error: Status check not available${NC}"
            echo "Expected status script: $status_script"
        fi
    fi
done
