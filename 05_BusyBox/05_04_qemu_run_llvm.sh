#!/bin/bash
set -e
set -u
# 获取脚本所在目录绝对路径
BASE_DIR=$(cd $(dirname "$0"); pwd)

OUTPUT_GCC="${BASE_DIR}/output_gcc"
ROOTFS_DIR="${OUTPUT_GCC}/rootfs_dir"
ROOTFS_IMG="${OUTPUT_GCC}/rootfs_img/rootfs.ext4"
KERNEL_IMG="${OUTPUT_GCC}/kernel/Image"

echo "============================================="
echo "05_04_qemu_run_gcc.sh | GCC内核 + ext4镜像 QEMU启动"
echo "============================================="
echo "脚本启动时间: $(date "+%Y-%m-%d %H:%M:%S")"
echo "脚本根目录: ${BASE_DIR}"
echo "============================================="

if [ ! -d "${OUTPUT_GCC}" ]; then
    echo "ERROR: output_gcc目录不存在，请先执行构建脚本"
    exit 1
fi
if [ ! -f "${KERNEL_IMG}" ]; then
    echo "ERROR: GCC内核 Image 缺失 ${KERNEL_IMG}"
    exit 1
fi
if [ ! -f "${ROOTFS_IMG}" ]; then
    echo "ERROR: ext4根文件镜像缺失 ${ROOTFS_IMG}"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真(GICv3)"
echo "内核路径: ${KERNEL_IMG}"
echo "ext4镜像路径: ${ROOTFS_IMG}"
echo "SSH转发：宿主机2222 → 开发板22端口"
echo "Telnet转发：宿主机2322 → 开发板23端口"
echo "QEMU退出快捷键：先按 Ctrl+A 松开，再按 X"
echo "============================================="

qemu-system-aarch64 \
-M virt,gic-version=3 \
-cpu cortex-a53 \
-m 1G \
-nographic \
-kernel ${KERNEL_IMG} \
-drive file=${ROOTFS_IMG},format=raw,if=virtio \
-net nic,model=virtio \
-net user,hostfwd=tcp::2222-:22,hostfwd=tcp::2323-:23 \
-append "root=/dev/vda rw console=ttyAMA0 init=/init"