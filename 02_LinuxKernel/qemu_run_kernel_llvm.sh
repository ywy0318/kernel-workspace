#!/bin/bash
# qemu_run_kernel_llvm.sh

CUR_DIR=$(pwd)
KERNEL_BUILD_DIR=./build-llvm

cd $KERNEL_BUILD_DIR || { echo "cd $KERNEL_BUILD_DIR failed"; exit 1; }

echo "=== QEMU 正常启动 Linux Kernel (LLVM arm64) ==="
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -m 1G \
    -nographic \
    -kernel Image

cd $CUR_DIR
