#!/bin/bash
# 04_09_07_qemu_uboot_llvm_kernel_llvm.sh
# 配套04_07预处理脚本｜方案2：双virtio磁盘，内核独立磁盘
# 组合：LLVM U-Boot + LLVM Kernel
set -e

echo "============================================="
echo "04_09_07_qemu_uboot_llvm_kernel_llvm.sh | LLVM U-Boot + LLVM Kernel QEMU(双磁盘方案2)"
echo "============================================="
echo "脚本启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

UBOOT_BIN="./output_llvm/uboot/u-boot.bin"
ROOTFS_IMG="./build_uboot_kernel_pair_ubllvm_kernllvm/rootfs.ext4"
KERNEL_DISK="./build_uboot_kernel_pair_ubllvm_kernllvm/kernel_Image.raw"

if [ ! -f "${UBOOT_BIN}" ];then
    echo "❌ 错误：LLVM编译U-Boot固件不存在 ${UBOOT_BIN}"
    exit 1
fi
if [ ! -f "${ROOTFS_IMG}" ] || [ ! -f "${KERNEL_DISK}" ];then
    echo "❌ 错误：双磁盘镜像缺失，请先执行 ./04_07_prepare_separate_kernel_disk.sh 生成资源"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真(U-Boot引导·双磁盘方案2)"
echo "U-Boot路径(LLVM): ${UBOOT_BIN}"
echo "virtio0根文件系统: ${ROOTFS_IMG}"
echo "virtio1独立内核磁盘: ${KERNEL_DISK}"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "已指定GICv3中断控制器适配virt平台，无SSH端口转发"
echo "============================================="

qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -bios "${UBOOT_BIN}" \
    -drive format=raw,file="${ROOTFS_IMG}",if=virtio \
    -drive format=raw,file="${KERNEL_DISK}",if=virtio,readonly=on \
    -nographic