#!/bin/bash
# 步骤2：交叉编译静态init

echo "[2/5] 交叉编译静态/init..."
aarch64-linux-gnu-gcc -static -o rootfs/init init.c
chmod +x rootfs/init

echo "[2/5] 完成"
