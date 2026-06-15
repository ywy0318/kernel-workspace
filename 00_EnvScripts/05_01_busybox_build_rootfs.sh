#!/bin/bash
# 05_01_busybox_build_rootfs.sh（最终修复版）
set -e
set -u

# 配置
BASE_DIR=$(pwd)
BUSYBOX_SRC="${BASE_DIR}/busybox-1.36.1"
ROOTFS_DIR="${BASE_DIR}/rootfs"
IMG_NAME="rootfs.cpio.gz"
CROSS_COMPILE="aarch64-linux-gnu-"

echo "[05_01] 开始构建 BusyBox 根文件系统..."

# 1. 清理旧文件
rm -rf "${ROOTFS_DIR}" "${IMG_NAME}"
mkdir -p "${ROOTFS_DIR}"

# 2. 进入源码目录编译 BusyBox
echo "[1/5] 配置并编译静态 BusyBox..."
cd "${BUSYBOX_SRC}"

# 加载配置并强制静态编译
make CROSS_COMPILE="${CROSS_COMPILE}" defconfig
sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

# 编译
make CROSS_COMPILE="${CROSS_COMPILE}" -j$(nproc)

# 检查编译结果
if [ ! -f busybox ]; then
    echo "❌ 错误：BusyBox 编译失败，没有生成二进制文件！"
    exit 1
fi
echo "✅ BusyBox 编译成功"

# 3. 关键：从源码目录安装到 rootfs
echo "[2/5] 安装到 rootfs..."
make CROSS_COMPILE="${CROSS_COMPILE}" CONFIG_PREFIX="${ROOTFS_DIR}" install
cd "${BASE_DIR}"

# 检查安装结果
if [ ! -d "${ROOTFS_DIR}/bin" ] || [ ! -f "${ROOTFS_DIR}/bin/busybox" ]; then
    echo "❌ 错误：BusyBox 安装失败，rootfs/bin 目录为空！"
    exit 1
fi
echo "✅ BusyBox 已成功安装到 ${ROOTFS_DIR}/bin/"

# 4. 创建系统目录和配置文件
echo "[3/5] 创建系统目录和配置..."
cd "${ROOTFS_DIR}"
mkdir -p dev etc etc/init.d proc sys tmp mnt lib64 home root
chmod 777 tmp

# 创建 /init 软链接
ln -sf /bin/busybox init

# 配置 rcS
cat > etc/init.d/rcS << EOF
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs tmpfs /tmp
mdev -s
EOF
chmod +x etc/init.d/rcS

# 配置 inittab
cat > etc/inittab << EOF
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF

# 创建设备节点
echo "[4/5] 创建设备节点..."
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1

# 5. 打包成 cpio.gz
echo "[5/5] 打包成 ${IMG_NAME}..."
find . | cpio -o -H newc | gzip > "${BASE_DIR}/${IMG_NAME}"
cd "${BASE_DIR}"

echo ""
echo "🎉 构建完成！"
echo "✅ 根文件系统目录：${ROOTFS_DIR}"
echo "✅ 可启动镜像：${IMG_NAME}"
echo "✅ rootfs/bin/ 目录大小：$(du -sh ${ROOTFS_DIR}/bin/)"
