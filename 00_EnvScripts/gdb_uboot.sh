#!/bin/bash
# gdb_uboot.sh

UBOOT_DIR=./u-boot-2023.04
GDB=aarch64-linux-gnu-gdb

cd $UBOOT_DIR || { echo "cd $UBOOT_DIR failed"; exit 1; }

$GDB u-boot -ex "target remote :1234"
