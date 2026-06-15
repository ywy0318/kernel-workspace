#!/bin/bash
# qemu_debug_uboot.sh

CUR_DIR=$(pwd)
UBOOT_DIR=./u-boot-2023.04

cd $UBOOT_DIR || { echo "cd $UBOOT_DIR failed"; exit 1; }

echo "=== QEMU 调试模式启动 U-Boot ==="
echo "QEMU 会暂停，等待 GDB 连接: target remote :1234"
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -m 1G \
    -nographic \
    -kernel u-boot \
    -s -S

cd $CUR_DIR
