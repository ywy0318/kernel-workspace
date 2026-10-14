#!/bin/bash
set -e
set -u

# 路径配置，和06_04_qemu_run_gcc.sh保持一致
OUTPUT_GCC="./output_gcc"
KERNEL_IMG="${OUTPUT_GCC}/kernel/Image"
# dump出来的dtb保存到output-gcc目录
DUMP_DTB="${OUTPUT_GCC}/virt_dump.dtb"

echo "====================================================="
echo "06_05_qemu_dump_dtb.sh | QEMU导出virt原生dtb"
echo "脚本启动时间: $(date "+%Y-%m-%d %H:%M:%S")"
echo "====================================================="

# 前置文件校验
if [ ! -d "${OUTPUT_GCC}" ]; then
    echo "ERROR: 目录不存在，请先执行 ./06_03_copy_kernel_buildroot_rootfs.sh 生成output-gcc"
    exit 1
fi

if [ ! -f "${KERNEL_IMG}" ]; then
    echo "ERROR: 缺失GCC内核 Image"
    exit 1
fi

echo "✅ 文件校验完成，准备dumpdtb"
echo "内核路径: ${KERNEL_IMG}"
echo "导出dtb输出: ${DUMP_DTB}"
echo "====================================================="

qemu-system-aarch64 \
-M virt,gic-version=3 \
-cpu cortex-a53 \
-m 1G \
-nographic \
-serial mon:stdio \
-machine virt,dumpdtb="${DUMP_DTB}" \
-kernel "${KERNEL_IMG}"

echo "✅ dumpdtb执行完成！"
ls -lh "${DUMP_DTB}"
