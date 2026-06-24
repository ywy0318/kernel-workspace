#!/bin/bash
# U-Boot:LLVM编译 | 内核:GCC编译 组合启动脚本
set -e

echo "============================================="
echo "04_05_qemu_uboot_llvm_kernel_gcc.sh | LLVM U-Boot + GCC Kernel QEMU"
echo "============================================="
echo "脚本启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

# 路径：uboot(llvm) + rootfs(gcc，内置gcc编译kernel)
UBOOT_BIN="./output_llvm/uboot/u-boot.bin"
ROOTFS_IMG="./output_gcc/rootfs/rootfs.ext4"

# 文件校验
if [ ! -f "${UBOOT_BIN}" ];then
    echo "❌ 错误：LLVM编译U-Boot不存在 ${UBOOT_BIN}"
    exit 1
fi
if [ ! -f "${ROOTFS_IMG}" ];then
    echo "❌ 错误：GCC根文件系统镜像不存在 ${ROOTFS_IMG}"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真(U-Boot引导)"
echo "U-Boot路径(LLVM): ${UBOOT_BIN}"
echo "根文件系统(内置GCC内核): ${ROOTFS_IMG}"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "已指定GICv3中断控制器适配virt平台，无SSH端口转发"
echo "============================================="

qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -bios "${UBOOT_BIN}" \
    -drive format=ext4,file="${ROOTFS_IMG}",if=virtio \
    -serial stdio \
    -nographic