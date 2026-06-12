#!/bin/bash
# 06_verify_rootfs.sh
# 功能：在宿主机上验证 rootfs.ext4 镜像是否合法、关键文件是否正常

set -e
set -u

IMG="rootfs.ext4"
TMP_MOUNT="./test_mount"

echo "[06] 开始验证 rootfs 镜像..."

# 1. 检查镜像文件是否存在
if [ ! -f "${IMG}" ]; then
    echo "❌ 错误：镜像文件 ${IMG} 不存在"
    exit 1
fi

# 2. 检查是否是 ext4 文件系统
echo "[1/5] 检查文件系统类型..."
if ! file "${IMG}" | grep -q "ext4 filesystem"; then
    echo "❌ 错误：${IMG} 不是 ext4 文件系统"
    exit 1
fi
echo "✅ 是合法的 ext4 文件系统"

# 3. 挂载镜像
echo "[2/5] 挂载镜像..."
mkdir -p "${TMP_MOUNT}"
sudo mount -o loop "${IMG}" "${TMP_MOUNT}"
echo "✅ 镜像已挂载到 ${TMP_MOUNT}"

# 4. 检查关键文件和目录
echo "[3/5] 检查关键文件和目录..."
declare -a CHECK_FILES=(
    "/init"
    "/bin/sh"
    "/bin/bash"
    "/dev/console"
    "/dev/null"
    "/proc"
    "/sys"
    "/tmp"
)

for file in "${CHECK_FILES[@]}"; do
    path="${TMP_MOUNT}${file}"
    if [ -e "${path}" ]; then
        echo "✅ ${file} 存在"
        # 检查可执行位
        if [[ "${file}" == "/init" || "${file}" == "/bin/sh" ]]; then
            if [ -x "${path}" ]; then
                echo "  ✅ ${file} 具有可执行权限"
            else
                echo "  ⚠️  警告：${file} 没有可执行权限"
            fi
        fi
    else
        echo "❌ ${file} 不存在"
    fi
done

# 5. 检查 /init 和 /bin/sh 的架构和链接方式
echo "[4/5] 检查可执行文件架构和链接方式..."
if command -v aarch64-linux-gnu-readelf &> /dev/null; then
    echo "--- /init 信息 ---"
    aarch64-linux-gnu-readelf -h "${TMP_MOUNT}/init" | grep "Class\|Machine"
    echo "是否静态链接："
    if ! aarch64-linux-gnu-readelf -l "${TMP_MOUNT}/init" | grep -q interpreter; then
        echo "✅ /init 是静态链接（无动态依赖）"
    else
        echo "⚠️  /init 是动态链接，可能需要依赖库"
    fi

    echo "--- /bin/sh 信息 ---"
    aarch64-linux-gnu-readelf -h "${TMP_MOUNT}/bin/sh" | grep "Class\|Machine"
    echo "是否静态链接："
    if ! aarch64-linux-gnu-readelf -l "${TMP_MOUNT}/bin/sh" | grep -q interpreter; then
        echo "✅ /bin/sh 是静态链接（无动态依赖）"
    else
        echo "⚠️  /bin/sh 是动态链接，可能需要依赖库"
    fi
else
    echo "⚠️  未找到 aarch64-linux-gnu-readelf，跳过架构检查"
fi

# 6. 卸载镜像
echo "[5/5] 卸载镜像..."
sudo umount "${TMP_MOUNT}"
rmdir "${TMP_MOUNT}"
echo "✅ 镜像已卸载"

echo "[06] 验证完成！如果没有红色错误，镜像基本可用"
