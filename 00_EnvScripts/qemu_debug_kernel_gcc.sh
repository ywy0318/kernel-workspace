#!/bin/bash
# qemu_debug_kernel_gcc.sh

CUR_DIR=$(pwd)
KERNEL_BUILD_DIR=./build-gcc

cd $KERNEL_BUILD_DIR || { echo "cd $KERNEL_BUILD_DIR failed"; exit 1; }

echo "=== QEMU 调试模式启动 Linux Kernel (GCC arm64) ==="
echo "QEMU 会暂停，等待 GDB 连接: target remote :1234"
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -m 1G \
    -nographic \
    -kernel Image \
    -s -S

cd $CUR_DIR
