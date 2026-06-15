#!/bin/bash
# 02_02_kernel_menuconfig.sh
# 内核可视化配置菜单，支持 GCC / LLVM 两套编译目录切换

CUR_DIR=$(pwd)

# 两套编译目录与对应源码
GCC_KERNEL="$CUR_DIR/linux-6.18-gcc"
GCC_BUILD="$CUR_DIR/build-gcc"
LLVM_KERNEL="$CUR_DIR/linux-6.18-llvm"
LLVM_BUILD="$CUR_DIR/build-llvm"

echo "=============================="
echo "  内核配置菜单选择"
echo "  1) GCC 版本 (build-gcc)"
echo "  2) LLVM 版本 (build-llvm)"
echo "=============================="
read -p "请输入序号 [1/2]: " CHOICE

case $CHOICE in
    1)
        KERNEL_DIR="$GCC_KERNEL"
        BUILD_DIR="$GCC_BUILD"
        ;;
    2)
        KERNEL_DIR="$LLVM_KERNEL"
        BUILD_DIR="$LLVM_BUILD"
        ;;
    *)
        echo "输入错误，退出脚本"
        exit 1
        ;;
esac

# 进入源码目录并打开配置界面
cd "$KERNEL_DIR" || { echo "进入内核目录失败"; exit 1; }
echo "正在打开配置界面，编译目录：$BUILD_DIR"
make O="$BUILD_DIR" menuconfig
