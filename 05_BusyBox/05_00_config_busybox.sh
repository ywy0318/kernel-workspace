#!/bin/bash
# 05_00_config_busybox.sh
# 功能：快速进入 BusyBox 图形化配置界面

set -e

BASE_DIR=$(pwd)
BUSYBOX_SRC="${BASE_DIR}/busybox-1.36.1"
CROSS_COMPILE="aarch64-linux-gnu-"

if [ ! -d "${BUSYBOX_SRC}" ]; then
    echo "❌ 错误：未找到 busybox-1.36.1 源码目录"
    exit 1
fi

cd "${BUSYBOX_SRC}"
echo "✅ 进入 BusyBox 配置界面，修改后保存退出即可"
make CROSS_COMPILE="${CROSS_COMPILE}" menuconfig

echo "✅ 配置已保存，可执行构建脚本编译"
