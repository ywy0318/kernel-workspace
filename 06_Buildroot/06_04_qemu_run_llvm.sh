#!/bin/bash
set -e
set -u
echo "============================================="
echo "06_04_qemu_run_llvm.sh | LLVM内核 + Buildroot rootfs.ext2 启动QEMU"
echo "============================================="
echo "脚本启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

KERNEL_IMG="./output_llvm/kernel/Image"
ROOTFS_IMG="./output_llvm/rootfs/rootfs.ext2"

# 文件校验
if [ ! -f "${KERNEL_IMG}" ];then
    echo "❌ 错误：内核镜像不存在 ${KERNEL_IMG}"
    exit 1
fi
if [ ! -f "${ROOTFS_IMG}" ];then
    echo "❌ 错误：根文件系统ext2镜像不存在 ${ROOTFS_IMG}"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真(GICv3)"
echo "内核路径: ${KERNEL_IMG}"
echo "根文件系统ext2镜像: ${ROOTFS_IMG}"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "============================================="

qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -kernel "${KERNEL_IMG}" \
    -drive format=raw,file="${ROOTFS_IMG}",if=virtio \
    -append "root=/dev/vda rw console=tty0 console=ttyAMA0 init=/sbin/init" \
    -nographic