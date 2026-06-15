#!/bin/bash
# 11_01_create_min_arm64_rootfs.sh
# 功能：用 qemu-debootstrap 拉取最小 arm64 Debian rootfs
set -euo pipefail

echo "====================================="
echo " 11_01 制作最小 arm64 rootfs（qemu-debootstrap）"
echo "====================================="

# 配置
ARCH="arm64"
DEBIAN_CODENAME="bullseye"
VARIANT="minbase"
ROOTFS_DIR="./arm64-min-rootfs"
MIRROR="https://mirrors.tuna.tsinghua.edu.cn/debian/"

# 安装依赖
echo "[1/4] 安装依赖..."
sudo apt update
sudo apt install -y debootstrap qemu-user-static binfmt-support

# 清理旧目录
sudo rm -rf "${ROOTFS_DIR}"
mkdir -p "${ROOTFS_DIR}"

# 拉取 rootfs
echo "[2/4] 拉取 ${ARCH} ${DEBIAN_CODENAME} rootfs..."
sudo qemu-debootstrap \
  --arch="${ARCH}" \
  --variant="${VARIANT}" \
  "${DEBIAN_CODENAME}" \
  "${ROOTFS_DIR}" \
  "${MIRROR}"

# 配置网络
echo "[3/4] 配置网络与基础文件..."
sudo cp /etc/resolv.conf "${ROOTFS_DIR}/etc/"

# 设置 root 密码
echo "root:root" | sudo chroot "${ROOTFS_DIR}" chpasswd

# 生成 fstab
sudo tee "${ROOTFS_DIR}/etc/fstab" >/dev/null <<'FSTAB'
/dev/vda1 / ext4 defaults 0 1
FSTAB

echo "[4/4] 完成！"
echo "✅ rootfs 路径：$(realpath ${ROOTFS_DIR})"
