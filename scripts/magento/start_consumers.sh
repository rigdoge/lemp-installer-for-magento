#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Magento 消费者列表
CONSUMERS=(
    "saveConfigProcessor"
    "product_action_attribute.update"
    "product_action_attribute.website.update"
    "catalog_website_attribute_value_sync"
    "media.storage.catalog.image.resize"
    "exportProcessor"
    "inventory.source.items.cleanup"
    "inventory.mass.update"
    "inventory.reservations.cleanup"
    "inventory.reservations.update"
    "inventory.reservations.updateSalabilityStatus"
    "inventory.indexer.sourceItem"
    "inventory.indexer.stock"
    "media.content.synchronization"
    "media.gallery.renditions.update"
    "media.gallery.synchronization"
    "codegeneratorProcessor"
    "sales.rule.update.coupon.usage"
    "sales.rule.quote.trigger.recollect"
    "product_alert"
    "async.operations.all"
)

# 获取 Magento 根目录
MAGENTO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 检查 Magento CLI 是否存在
if [ ! -f "$MAGENTO_ROOT/bin/magento" ]; then
    echo -e "${RED}错误：找不到 Magento CLI${NC}"
    echo "预期路径: $MAGENTO_ROOT/bin/magento"
    exit 1
fi

# 检查日志目录
LOG_DIR="$MAGENTO_ROOT/var/log/consumers"
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# 停止所有现有的消费者进程
echo -e "${YELLOW}停止现有的消费者进程...${NC}"
pkill -f "bin/magento queue:consumers:start"

# 启动每个消费者
for consumer in "${CONSUMERS[@]}"; do
    echo -e "${GREEN}启动消费者: $consumer${NC}"
    nohup php "$MAGENTO_ROOT/bin/magento" queue:consumers:start "$consumer" --single-thread > "$LOG_DIR/$consumer.log" 2>&1 &
    
    # 等待一秒，避免同时启动太多进程
    sleep 1
done

echo -e "${GREEN}所有消费者已启动${NC}"
echo "消费者日志目录: $LOG_DIR"
echo "使用以下命令查看进程状态："
echo "ps aux | grep 'queue:consumers:start'"
echo "使用以下命令查看特定消费者日志："
echo "tail -f $LOG_DIR/consumer-name.log" 