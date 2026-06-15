#!/bin/bash
set -e
KERN_VER="6.18"
SAVE_DIR="$HOME/workspace/02_LinuxKernel"
TAR_FILE="linux-${KERN_VER}.tar.xz"
SRC_DIR="${SAVE_DIR}/linux-${KERN_VER}"

# 创建根目录
mkdir -p "${SAVE_DIR}"
cd "${SAVE_DIR}"

# 判断源码目录是否已存在，存在则直接退出
if [ -d "${SRC_DIR}" ]; then
    echo "目录 ${SRC_DIR} 已存在，无需重复下载和解压"
    exit 0
fi

# 断点续传下载
wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/${TAR_FILE}"

# 解压
echo "开始解压 ${TAR_FILE} ..."
tar -Jxf "${TAR_FILE}"

echo "====================================="
echo "Linux ${KERN_VER} 源码下载解压完成！"
echo "源码路径：${SRC_DIR}"
echo "====================================="
