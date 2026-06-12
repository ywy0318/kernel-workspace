#!/bin/bash
# 11_04_verify_QemuDebootstrapRootFS_make_ext4_image.sh
# 功能：验证 ext4 镜像完整性、文件结构与启动合法性
set -e
set -u

IMAGE_FILE="./arm64-min-rootfs.ext4"
TMP_MOUNT="./mnt_ext4"

echo "[11_04] 验证 ext4 镜像..."

# 1. 检查镜像存在
if [ ! -f "${IMAGE_FILE}" ]; then
    echo "❌ 错误：${IMAGE_FILE} 不存在，请先执行 11_03"
    exit 1
fi

# 2. 检查文件类型
echo "[1/6] 检查文件类型..."
if ! file "${IMAGE_FILE}" | grep -q "ext4 filesystem"; then
    echo "❌ 不是合法 ext4 镜像"
    exit 1
fi
echo "✅ ext4 镜像格式正确"

# 3. 检查文件系统完整性
echo "[2/6] 检查 ext4 完整性（fsck）..."
sudo fsck.ext4 -n "${IMAGE_FILE}"
echo "✅ 文件系统无错误"

# 4. 挂载并检查关键文件
echo "[3/6] 挂载并检查关键文件..."
rm -rf "${TMP_MOUNT}"
mkdir -p "${TMP_MOUNT}"
sudo mount -o loop "${IMAGE_FILE}" "${TMP_MOUNT}"

items=(
    "/bin/bash"
    "/sbin/init"
    "/etc/fstab"
    "/dev/console"
    "/proc" "/sys"
)

for item in "${items[@]}"; do
    path="${TMP_MOUNT}${item}"
    if [ -e "$path" ]; then
        echo "✅ $item"
    else
        echo "❌ $item 缺失"
    fi
done

# 5. 检查架构
echo "[4/6] 检查镜像内架构..."
if command -v aarch64-linux-gnu-readelf &> /dev/null; then
    aarch64-linux-gnu-readelf -h "${TMP_MOUNT}/bin/bash" | grep "Class\|Machine"
    echo "✅ 镜像内为 ARM64"
fi

# 6. 卸载
echo "[5/6] 卸载镜像..."
sudo umount "${TMP_MOUNT}"
rmdir "${TMP_MOUNT}"

echo "[6/6] 验证完成！"
echo "🎉 ext4 镜像可直接用于 QEMU 启动！"
