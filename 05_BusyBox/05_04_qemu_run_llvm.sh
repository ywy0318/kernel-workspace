#!/bin/bash
set -e
# 05_04_qemu_run_llvm.sh | LLVM内核 + BusyBox根文件系统 QEMU启动
OUTPUT_LLVM="./output_llvm"
KERNEL_IMG="${OUTPUT_LLVM}/kernel/Image"
ROOTFS_IMG="${OUTPUT_LLVM}/rootfs_img/rootfs.ext4"

echo "============================================="
echo "05_04_qemu_run_llvm.sh | LLVM内核 + BusyBox根文件系统 QEMU启动"
echo "============================================="
echo "脚本启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

# 文件完整性校验
if [ ! -f "${KERNEL_IMG}" ];then
    echo "❌ 错误：LLVM内核镜像不存在 ${KERNEL_IMG}"
    exit 1
fi
if [ ! -f "${ROOTFS_IMG}" ];then
    echo "❌ 错误：BusyBox根文件系统镜像不存在 ${ROOTFS_IMG}"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真(GICv3)"
echo "内核路径: ${KERNEL_IMG}"
echo "根文件系统镜像: ${ROOTFS_IMG}"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "============================================="

qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -kernel "${KERNEL_IMG}" \
    -drive format=raw,file="${ROOTFS_IMG}",if=virtio \
    -append "root=/dev/vda rw console=tty0 console=ttyAMA0 init=/init" \
    -nographic