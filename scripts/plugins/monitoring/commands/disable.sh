#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 设置目录路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AVAILABLE_DIR="$SCRIPT_DIR/../available"
ENABLED_DIR="$SCRIPT_DIR/../enabled"

# 检查参数
if [ "$#" -ne 1 ]; then
    echo -e "${RED}Error: Missing monitor name${NC}"
    echo "Usage: $0 <monitor-name>"
    exit 1
fi

MONITOR_NAME="$1"
MONITOR_FILE="$MONITOR_NAME.monitor"
SOURCE="$AVAILABLE_DIR/$MONITOR_FILE"
TARGET="$ENABLED_DIR/$MONITOR_FILE"

# 检查监控文件是否存在
if [ ! -f "$SOURCE" ]; then
    echo -e "${RED}Error: Monitor '$MONITOR_NAME' not found${NC}"
    exit 1
fi

# 检查是否已禁用
if [ ! -L "$TARGET" ]; then
    echo -e "${GREEN}Monitor '$MONITOR_NAME' is already disabled${NC}"
    exit 0
fi

# 如果监控有停止脚本，执行它
if [ -x "$SOURCE.stop" ]; then
    echo "Running stop script..."
    "$SOURCE.stop"
fi

# 删除软链接
rm -f "$TARGET"

# 验证是否成功
if [ ! -L "$TARGET" ]; then
    echo -e "${GREEN}Successfully disabled monitor '$MONITOR_NAME'${NC}"
else
    echo -e "${RED}Failed to disable monitor '$MONITOR_NAME'${NC}"
    exit 1
fi
