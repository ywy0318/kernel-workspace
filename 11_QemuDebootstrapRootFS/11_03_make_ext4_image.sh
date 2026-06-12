#!/bin/bash
# 11_03_make_ext4_image.sh
# 功能：将 arm64-min-rootfs 打包为 ext4 镜像
set -euo pipefail

ROOTFS_DIR="./arm64-min-rootfs"
IMAGE_FILE="./arm64-min-rootfs.ext4"
IMAGE_SIZE="512M"

echo "====================================="
echo " 11_03 制作 ext4 镜像"
echo "====================================="

# 检查 rootfs 目录
if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ 错误：${ROOTFS_DIR} 不存在，请先执行 11_01"
    exit 1
fi

# 创建空镜像
echo "[1/3] 创建 ${IMAGE_SIZE} 空镜像..."
rm -f "${IMAGE_FILE}"
dd if=/dev/zero of="${IMAGE_FILE}" bs=1M count=512

# 格式化为 ext4
echo "[2/3] 格式化为 ext4..."
sudo mkfs.ext4 "${IMAGE_FILE}"

# 挂载并复制
echo "[3/3] 复制 rootfs 到镜像..."
TMP_MOUNT=$(mktemp -d)
sudo mount "${IMAGE_FILE}" "${TMP_MOUNT}"
sudo cp -a "${ROOTFS_DIR}"/* "${TMP_MOUNT}/"
sudo umount "${TMP_MOUNT}"
rmdir "${TMP_MOUNT}"

echo "✅ 镜像完成：$(realpath ${IMAGE_FILE})"
