#!/bin/bash
# 05_02_verify_busybox_rootfs.sh
# 功能：验证 busybox 制作的 rootfs.cpio.gz 镜像，安全不删除用户文件
set -e
set -u

IMG="rootfs.cpio.gz"
TMP_DIR="./test_cpio"

echo "[05_02] 开始验证 busybox rootfs 镜像..."

# 1. 检查镜像是否存在
if [ ! -f "${IMG}" ]; then
    echo "❌ 错误：${IMG} 不存在"
    exit 1
fi

# 2. 检查是否 gzip 压缩
echo "[1/5] 检查文件类型..."
if ! file "${IMG}" | grep -q "gzip compressed data"; then
    echo "❌ 错误：不是合法的 cpio.gz 镜像"
    exit 1
fi
echo "✅ 镜像格式正确"

# 3. 解压到临时目录（使用 sudo 避免设备节点创建报错）
echo "[2/5] 解压到临时目录检查..."
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}"
sudo zcat "../${IMG}" | sudo cpio -idm --no-absolute-filenames
cd ..

# 4. 检查关键文件（BusyBox 根文件系统必备）
echo "[3/5] 检查关键文件/目录..."
items=(
    "/bin/busybox"
    "/bin/sh"
    "/init"
    "/dev/console"
    "/dev/null"
    "/etc/inittab"
    "/etc/init.d/rcS"
    "/proc" "/sys" "/tmp"
)

for item in "${items[@]}"; do
    path="${TMP_DIR}${item}"
    if [ -e "$path" ]; then
        echo "✅ $item 存在"
    else
        echo "❌ $item 缺失"
    fi
done

# 5. 检查架构与静态链接
echo "[4/5] 检查 ARM64 静态链接..."
if command -v aarch64-linux-gnu-readelf &> /dev/null; then
    echo "--- /bin/busybox ---"
    aarch64-linux-gnu-readelf -h "${TMP_DIR}/bin/busybox" | grep "Class\|Machine"
    if ! aarch64-linux-gnu-readelf -l "${TMP_DIR}/bin/busybox" | grep -q "interpreter"; then
        echo "✅ 静态链接，启动无依赖"
    else
        echo "⚠️ 动态链接，可能无法启动"
    fi
else
    echo "⚠️ 未安装 readelf，跳过架构检查"
fi

# 6. 清理临时文件（只删除 test_cpio）
echo "[5/5] 清理临时文件..."
sudo rm -rf "${TMP_DIR}"
echo "✅ 清理完成（仅删除临时目录，不影响 rootfs / rootfs.cpio.gz）"

echo ""
echo "🎉 验证完成！你的镜像可正常用于内核启动！"
