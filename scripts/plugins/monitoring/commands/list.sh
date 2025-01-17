#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 设置目录路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AVAILABLE_DIR="$SCRIPT_DIR/../available"
ENABLED_DIR="$SCRIPT_DIR/../enabled"

# 检查目录是否存在
if [ ! -d "$AVAILABLE_DIR" ] || [ ! -d "$ENABLED_DIR" ]; then
    echo "Error: Required directories not found"
    exit 1
fi

echo -e "${GREEN}Available Monitors:${NC}"
echo "===================="
if [ -n "$(ls -A $AVAILABLE_DIR 2>/dev/null)" ]; then
    for monitor in "$AVAILABLE_DIR"/*.monitor; do
        if [ -f "$monitor" ]; then
            name=$(basename "$monitor")
            if [ -L "$ENABLED_DIR/$name" ]; then
                echo -e "  ${GREEN}✓${NC} ${name%.monitor} (enabled)"
            else
                echo -e "  ${YELLOW}×${NC} ${name%.monitor} (disabled)"
            fi
        fi
    done
else
    echo "No monitors available"
fi

echo ""
echo "Use: ./enable.sh <monitor> to enable a monitor"
echo "Use: ./disable.sh <monitor> to disable a monitor"
