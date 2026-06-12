#!/bin/bash
# qemu_run_uboot.sh

CUR_DIR=$(pwd)
UBOOT_DIR=./u-boot-2023.04

cd $UBOOT_DIR || { echo "cd $UBOOT_DIR failed"; exit 1; }

echo "=== QEMU 正常启动 U-Boot (virt arm64) ==="
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -m 1G \
    -nographic \
    -kernel u-boot

cd $CUR_DIR
