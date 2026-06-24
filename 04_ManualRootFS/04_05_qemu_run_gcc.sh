#!/bin/bash
set -e
set -u

# 路径配置
OUTPUT_GCC="./output_gcc"
RAW_ROOTFS="${OUTPUT_GCC}/rootfs/rootfs.ext4"
KERNEL_IMG="${OUTPUT_GCC}/kernel/Image"

echo "============================================="
echo "04_05_qemu_run_gcc.sh | GCC内核直接启动QEMU"
echo "============================================="
# 打印启动前时间
echo "脚本启动时间: $(date "+%Y-%m-%d %H:%M:%S")"
echo "============================================="

# 校验文件存在
if [ ! -d "${OUTPUT_GCC}" ]; then
    echo "ERROR: 请先执行 ./04_04_copy_uboot_kernel_rootfs.sh 生成output_gcc目录"
    exit 1
fi
if [ ! -f "${KERNEL_IMG}" ]; then
    echo "ERROR: 缺失GCC内核 Image"
    exit 1
fi
if [ ! -f "${RAW_ROOTFS}" ]; then
    echo "ERROR: 缺失rootfs.ext4"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真"
echo "内核路径: ${KERNEL_IMG}"
echo "根文件系统: ${RAW_ROOTFS}"
echo "SSH转发：宿主机2222 → 开发板22端口"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "已指定GICv2中断控制器适配virt平台"
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