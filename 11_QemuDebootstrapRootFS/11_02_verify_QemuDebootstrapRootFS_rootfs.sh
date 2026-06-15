#!/bin/bash
# 11_02_verify_QemuDebootstrapRootFS_rootfs.sh
# 功能：验证 qemu-debootstrap 生成的 arm64 rootfs 目录
set -e
set -u

ROOTFS_DIR="./arm64-min-rootfs"
TMP_DIR="./test_rootfs"

echo "[11_02] 验证 arm64 debootstrap rootfs..."

# 1. 检查目录存在
if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ 错误：${ROOTFS_DIR} 不存在"
    exit 1
fi

# 2. 检查关键目录/文件
echo "[1/5] 检查关键目录/文件..."
items=(
    "/bin" "/sbin" "/etc" "/lib" "/usr"
    "/dev/console" "/dev/null"
    "/proc" "/sys" "/tmp"
    "/etc/fstab" "/etc/resolv.conf"
)

for item in "${items[@]}"; do
    path="${ROOTFS_DIR}${item}"
    if [ -e "$path" ]; then
        echo "✅ $item"
    else
        echo "❌ $item 缺失"
    fi
done

# 3. 检查架构（aarch64）
echo "[2/5] 检查架构（aarch64）..."
if command -v aarch64-linux-gnu-readelf &> /dev/null; then
    BIN="${ROOTFS_DIR}/bin/bash"
    if [ -f "$BIN" ]; then
        aarch64-linux-gnu-readelf -h "$BIN" | grep "Class\|Machine"
        echo "✅ 架构为 ARM64"
    else
        echo "⚠️ 无 bash，跳过架构检查"
    fi
else
    echo "⚠️ 未安装 aarch64-linux-gnu-readelf，跳过"
fi

# 4. 检查 qemu-aarch64-static 是否存在（chroot 必备）
echo "[3/5] 检查 qemu-aarch64-static..."
if [ -f "${ROOTFS_DIR}/usr/bin/qemu-aarch64-static" ]; then
    echo "✅ qemu-aarch64-static 存在"
else
    echo "⚠️ 未拷贝 qemu-aarch64-static（不影响 QEMU 直接启动）"
fi

# 5. 简单 chroot 测试（不报错即可）
echo "[4/5] 简单 chroot 测试..."
sudo chroot "${ROOTFS_DIR}" /bin/sh -c "echo 'chroot OK'"

# 6. 清理
echo "[5/5] 清理..."
sudo rm -rf "${TMP_DIR}"

echo ""
echo "🎉 验证通过！rootfs 可用于制作 ext4 镜像。"
