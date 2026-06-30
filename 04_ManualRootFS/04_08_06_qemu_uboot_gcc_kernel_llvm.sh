#!/bin/bash
set -e
echo "============================================="
echo "04_08_06_qemu_uboot_gcc_kernel_llvm.sh | GCC U-Boot + LLVM Kernel"
echo "============================================="
echo "启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

IMG_DIR="./out_gcc_uboot_llvm_kernel"
UBOOT_BIN="${IMG_DIR}/u-boot.bin"
ROOTFS_IMG="${IMG_DIR}/rootfs.ext4"
DTB_FILE="${IMG_DIR}/qemu-arm64.dtb"

if [ ! -f "${UBOOT_BIN}" ] || [ ! -f "${ROOTFS_IMG}" ] || [ ! -f "${DTB_FILE}" ];then
    echo "❌ 资源缺失，请先执行 ./04_06_prepare_uboot_kernel_img.sh"
    exit 1
fi

echo "✅ 校验通过"
echo "U-Boot: ${UBOOT_BIN}"
echo "rootfs: ${ROOTFS_IMG}"
echo "dtb: ${DTB_FILE}"
echo "退出快捷键：Ctrl+A 松开再按 X"
echo "============================================="

qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -bios "${UBOOT_BIN}" \
    -drive format=raw,file="${ROOTFS_IMG}",if=virtio \
    -dtb "${DTB_FILE}" \
    -nographic