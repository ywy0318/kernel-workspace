#!/bin/bash
# 04_05_qemu_run_llvm.sh | LLVM内核直接启动QEMU
# 移除SSH端口转发hostfwd参数，统一virt GICv3配置
set -e

echo "============================================="
echo "04_05_qemu_run_llvm.sh | LLVM内核直接启动QEMU"
echo "============================================="
echo "脚本启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

KERNEL_IMG="./output_llvm/kernel/Image"
ROOTFS_IMG="./output_llvm/rootfs/rootfs.ext4"

# 文件校验
if [ ! -f "${KERNEL_IMG}" ];then
    echo "❌ 错误：内核镜像不存在 ${KERNEL_IMG}"
    exit 1
fi
if [ ! -f "${ROOTFS_IMG}" ];then
    echo "❌ 错误：根文件系统镜像不存在 ${ROOTFS_IMG}"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真"
echo "内核路径: ${KERNEL_IMG}"
echo "根文件系统: ${ROOTFS_IMG}"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "已指定GICv3中断控制器适配virt平台"
echo "============================================="

# 关键点：删掉 -serial stdio，-nographic 自动接管串口stdio
qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -kernel "${KERNEL_IMG}" \
    -drive format=raw,file="${ROOTFS_IMG}",if=virtio \
    -append "root=/dev/vda rw console=tty0 console=ttyAMA0 init=/init" \
    -nographic