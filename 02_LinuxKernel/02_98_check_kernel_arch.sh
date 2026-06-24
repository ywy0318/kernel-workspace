#!/bin/bash
CUR_DIR=$(pwd)
GCC_IMG="$CUR_DIR/build-gcc/Image"
LLVM_IMG="$CUR_DIR/build-llvm/Image"

echo "1. 校验GCC编译镜像"
if [ -f "$GCC_IMG" ]; then
    echo "=== file $GCC_IMG ==="
    file "$GCC_IMG"
else
    echo "GCC镜像不存在：$GCC_IMG"
fi

echo -e "\n2. 校验LLVM编译镜像"
if [ -f "$LLVM_IMG" ]; then
    echo "=== file $LLVM_IMG ==="
    file "$LLVM_IMG"
else
    echo "LLVM镜像不存在：$LLVM_IMG"
fi