#!/bin/bash
set -e
set -u

# 路径配置
OUTPUT_LLVM="./output_llvm"
RAW_ROOTFS="${OUTPUT_LLVM}/rootfs/rootfs.ext4"
KERNEL_IMG="${OUTPUT_LLVM}/kernel/Image"

echo "============================================="
echo "04_05_qemu_run_llvm.sh | LLVM内核直接启动QEMU"
echo "============================================="
# 打印启动前时间
echo "脚本启动时间: $(date "+%Y-%m-%d %H:%M:%S")"
echo "============================================="
# 校验文件存在
if [ ! -d "${OUTPUT_LLVM}" ]; then
    echo "ERROR: 请先执行 ./04_04_copy_uboot_kernel_rootfs.sh 生成output_llvm目录"
    exit 1
fi
if [ ! -f "${KERNEL_IMG}" ]; then
    echo "ERROR: 缺失LLVM内核 Image"
    exit 1
fi
if [ ! -f "${RAW_ROOTFS}" ]; then
    echo "ERROR: 缺失rootfs.ext4"
    exit 1
fi

echo "✅ 文件校验完成，准备启动aarch64 virt仿真"
echo "内核路径: ${KERNEL_IMG}"
echo "根文件系统: ${RAW_ROOTFS}"
echo "SSH转发：宿主机2223 → 开发板22端口（与GCC区分）"
echo "============================================="

#qemu-system-aarch64 \
#-M virt \
#-cpu cortex-a53 \
#-m 1G \
#-nographic \
#-kernel "${KERNEL_IMG}" \
#-drive file="${RAW_ROOTFS}",format=raw,if=virtio \
#-net nic,model=virtio \
#-net user,hostfwd=tcp::2223-:22 \
#-append "root=/dev/vda rw console=ttyAMA0 init=/init"

# QEMU aarch64 核心参数，删除hostfwd端口转发
qemu-system-aarch64 \
    -M virt,gic-version=3 \
    -cpu cortex-a53 \
    -smp 1 \
    -m 1G \
    -kernel "${KERNEL_IMG}" \
    -drive format=ext4,file="${ROOTFS_IMG}",if=virtio \
    -serial stdio \
    -append "root=/dev/vda rw console=tty0 console=ttyAMA0 init=/init" \
    -nographic