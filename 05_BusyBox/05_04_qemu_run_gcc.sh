#!/bin/bash
set -e
set -u
# 路径配置，与05_03拷贝脚本输出目录对齐
OUTPUT_GCC="./output_gcc"
RAW_ROOTFS="${OUTPUT_GCC}/rootfs_img/rootfs.ext4"
KERNEL_IMG="${OUTPUT_GCC}/kernel/Image"

echo "============================================="
echo "05_04_qemu_run_gcc.sh | GCC内核 + BusyBox根文件系统 QEMU启动"
echo "============================================="
echo "脚本启动时间: $(date "+%Y-%m-%d %H:%M:%S")"
echo "============================================="

# 前置文件校验
if [ ! -d "${OUTPUT_GCC}" ]; then
    echo "ERROR: output_gcc目录不存在，请先执行 ./05_03_copy_kernel_busybox_rootfs.sh"
    exit 1
fi
if [ ! -f "${KERNEL_IMG}" ]; then
    echo "ERROR: GCC内核 Image 缺失 ${KERNEL_IMG}"
    exit 1
fi
if [ ! -f "${RAW_ROOTFS}" ]; then
    echo "ERROR: BusyBox rootfs.ext4 镜像缺失 ${RAW_ROOTFS}"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真(GICv3)"
echo "内核路径: ${KERNEL_IMG}"
echo "根文件系统镜像: ${RAW_ROOTFS}"
echo "SSH转发：宿主机2222 → 开发板22端口"
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
-append "root=/dev/vda rw console=tty0 console=ttyAMA0 init=/init"