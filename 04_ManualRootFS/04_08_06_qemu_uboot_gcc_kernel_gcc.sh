#!/bin/bash
# 04_08_06_qemu_uboot_gcc_kernel_gcc.sh
# 配套04_06预处理脚本，方案1：Image内置rootfs单virtio磁盘
# 组合：GCC U-Boot + GCC Kernel
set -e

echo "============================================="
echo "04_08_06_qemu_uboot_gcc_kernel_gcc.sh | GCC U-Boot + GCC Kernel QEMU"
echo "============================================="
echo "脚本启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

# U-Boot固件路径
UBOOT_BIN="./output_gcc/uboot/u-boot.bin"
# 04_06脚本生成的内置内核rootfs镜像
ROOTFS_IMG="./out_gcc_uboot_gcc_kernel/rootfs.ext4"

# 文件校验
if [ ! -f "${UBOOT_BIN}" ];then
    echo "❌ 错误：GCC编译U-Boot不存在 ${UBOOT_BIN}"
    exit 1
fi
if [ ! -f "${ROOTFS_IMG}" ];then
    echo "❌ 错误：组合镜像不存在，请先执行04_06_prepare_uboot_kernel_img.sh"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真(U-Boot引导·单磁盘方案1)"
echo "U-Boot路径(GCC): ${UBOOT_BIN}"
echo "根文件系统(内置GCC内核): ${ROOTFS_IMG}"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "已指定GICv3中断控制器适配virt平台，无SSH端口转发"
echo "============================================="

# 单virtio磁盘，无-serial stdio，drive统一format=raw
qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -bios "${UBOOT_BIN}" \
    -drive format=raw,file="${ROOTFS_IMG}",if=virtio \
    -nographic