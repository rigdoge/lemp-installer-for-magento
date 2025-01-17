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
    echo "Available monitors:"
    ls -1 "$AVAILABLE_DIR" | sed 's/\.monitor$//'
    exit 1
fi

# 检查是否已启用
if [ -L "$TARGET" ]; then
    echo -e "${GREEN}Monitor '$MONITOR_NAME' is already enabled${NC}"
    exit 0
fi

# 创建软链接
ln -s "$SOURCE" "$TARGET"

# 验证是否成功
if [ -L "$TARGET" ]; then
    echo -e "${GREEN}Successfully enabled monitor '$MONITOR_NAME'${NC}"
    
    # 如果监控有启动脚本，执行它
    if [ -x "$SOURCE.init" ]; then
        echo "Running initialization script..."
        "$SOURCE.init"
    fi
else
    echo -e "${RED}Failed to enable monitor '$MONITOR_NAME'${NC}"
    exit 1
fi
