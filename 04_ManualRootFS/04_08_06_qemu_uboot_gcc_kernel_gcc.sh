#!/bin/bash
set -e
echo "=========================================="
echo "04_08_06_qemu_uboot_gcc_kernel_gcc.sh | GCC U-Boot + GCC Kernel"
echo "=========================================="
echo "启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# 修正 IMG_DIR：使用相对路径 ./，不要用 /
IMG_DIR="./out_gcc_uboot_gcc_kernel"
UBOOT_BIN="${IMG_DIR}/u-boot.bin"
ROOTFS_IMG="${IMG_DIR}/rootfs.ext4"
# 注意：我们已经不用 -dtb 了，所以可以不定义 DTB_FILE，但保留也没关系
DTB_FILE="${IMG_DIR}/qemu-arm64.dtb"

# 校验
if [ ! -f "${UBOOT_BIN}" ] || [ ! -f "${ROOTFS_IMG}" ]; then
    echo "资源缺失，请先执行 ./04_06_prepare_uboot_kernel_img.sh"
    exit 1
fi

echo "✅ 校验通过"
echo "U-Boot: ${UBOOT_BIN}"
echo "rootfs: ${ROOTFS_IMG}"
# 不再显示 dtb，因为我们不传它
echo "退出快捷键: Ctrl+A 松开再按 X"
echo "=========================================="

qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -bios "${UBOOT_BIN}" \
    -drive format=raw,file="${ROOTFS_IMG}",if=virtio \
    -nographic