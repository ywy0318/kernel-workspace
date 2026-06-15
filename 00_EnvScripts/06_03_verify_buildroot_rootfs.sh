#!/bin/bash

# 配置区
BUILDROOT_DIR="/home/ubuntu/workspace/06_Buildroot/buildroot-2023.02.9"
IMAGE_PATH="$BUILDROOT_DIR/output/images/rootfs.ext4"

echo "=================================================="
echo "[06_02] 开始验证 Buildroot rootfs 镜像（busybox）"
echo "=================================================="

# 1. 检查文件是否存在
if [ ! -e "$IMAGE_PATH" ]; then
    echo "❌ 错误：镜像文件不存在！"
    exit 1
fi
echo "✅ 镜像文件存在"

# 2. 关键：处理符号链接，找到真正的 ext4 文件
REAL_IMAGE=$(readlink -f "$IMAGE_PATH")
echo "ℹ️  真正的镜像文件：$REAL_IMAGE"

# 3. 检查文件系统类型（对真实文件检查）
echo -e "\n[1/6] 检查文件系统类型..."
fs_type=$(file "$REAL_IMAGE" | grep -o "ext4 filesystem data")
if [ -z "$fs_type" ]; then
    echo "❌ 错误：不是 ext4 镜像"
    exit 1
fi
echo "✅ 是 ext4 文件系统"

echo -e "\n✅ 验证通过！镜像路径：$IMAGE_PATH"
