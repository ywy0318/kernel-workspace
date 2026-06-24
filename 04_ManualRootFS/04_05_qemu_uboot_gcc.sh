#!/bin/bash
set -e
set -u

OUTPUT_GCC="./output_gcc"
UBOOT_BIN="${OUTPUT_GCC}/uboot/u-boot.bin"
RAW_ROOTFS="${OUTPUT_GCC}/rootfs/rootfs.ext4"

echo "============================================="
echo "04_05_qemu_uboot_gcc.sh | GCC U-Boot引导仿真"
echo "============================================="

# 校验文件
if [ ! -f "${UBOOT_BIN}" ]; then
    echo "ERROR: 缺失GCC编译u-boot.bin，请先执行拷贝脚本"
    exit 1
fi
if [ ! -f "${RAW_ROOTFS}" ]; then
    echo "ERROR: 缺失rootfs.ext4"
    exit 1
fi

echo "✅ U-Boot镜像校验完成，进入U-Boot命令行"
echo "进入uboot后手动执行启动命令："
echo "virtio dev 0"
echo "load virtio 0 0x40080000 /Image"
echo "booti 0x40080000 - \${fdt_addr}"
echo "SSH转发端口：2222"
echo "============================================="

qemu-system-aarch64 \
-M virt \
-cpu cortex-a53 \
-m 1G \
-nographic \
-kernel "${UBOOT_BIN}" \
-drive file="${RAW_ROOTFS}",format=raw,if=virtio \
-net nic,model=virtio \
-net user,hostfwd=tcp::2222-:22