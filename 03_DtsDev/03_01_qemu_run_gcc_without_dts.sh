#!/bin/bash
set -e
set -u
# 路径配置，对应06_03脚本输出目录
OUTPUT_GCC="./output_gcc"
RAW_ROOTFS="${OUTPUT_GCC}/rootfs/rootfs.ext2"
KERNEL_IMG="${OUTPUT_GCC}/kernel/Image"

echo "============================================="
echo "06_04_qemu_run_gcc.sh | GCC内核 + Buildroot rootfs.ext2 启动QEMU"
echo "============================================="
echo "脚本启动时间: $(date "+%Y-%m-%d %H:%M:%S")"
echo "============================================="

# 前置文件校验
if [ ! -d "${OUTPUT_GCC}" ]; then
    echo "ERROR: 目录不存在，请先执行 ./06_03_copy_kernel_buildroot_rootfs.sh 生成output_gcc"
    exit 1
fi
if [ ! -f "${KERNEL_IMG}" ]; then
    echo "ERROR: 缺失GCC内核 Image"
    exit 1
fi
if [ ! -f "${RAW_ROOTFS}" ]; then
    echo "ERROR: 缺失Buildroot rootfs.ext2 文件系统镜像"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真(GICv3)"
echo "内核路径: ${KERNEL_IMG}"
echo "根文件系统ext2镜像: ${RAW_ROOTFS}"
echo "SSH转发：宿主机2222 → 虚拟机22端口"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "============================================="

qemu-system-aarch64 \
-M virt,gic-version=3 \
-cpu cortex-a53 \
-m 1G \
-nographic \
-serial mon:stdio \
-d guest_errors \
-kernel "${KERNEL_IMG}" \
-drive file="${RAW_ROOTFS}",format=raw,if=virtio \
-net nic,model=virtio \
-net user,hostfwd=tcp::2222-:22 \
-append "root=/dev/vda rw console=tty0 console=ttyAMA0 init=/sbin/init"