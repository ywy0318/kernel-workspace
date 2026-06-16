#!/bin/bash
# 02_00_kernel_menuconfig.sh
# 内核可视化配置菜单，GCC / LLVM 双版本切换
# 退出自动适配新配置 + grep批量校验virtio驱动

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

# 1. 自动适配内核新增配置，消除编译交互弹窗
echo -e "\n=== 正在自动适配内核新增配置 olddefconfig ==="
make O="$BUILD_DIR" olddefconfig
echo "配置适配完成"

# 2. grep批量校验 VIRTIO 三个关键驱动是否开启
echo -e "\n=== 校验 VIRTIO 驱动配置状态 ==="
CONFIG_FILE="${BUILD_DIR}/.config"
MISSING=0
CFG_LIST=("VIRTIO_PCI" "VIRTIO_NET" "VIRTIO_BLK")
ALL_MATCH=$(grep -E "^CONFIG_(VIRTIO_PCI|VIRTIO_NET|VIRTIO_BLK)=y" "$CONFIG_FILE")

for cfg in "${CFG_LIST[@]}"; do
    if echo "$ALL_MATCH" | grep -q "^CONFIG_${cfg}=y"; then
        echo "✅ 已开启: CONFIG_$cfg=y"
    else
        echo "❌ 缺失或未内置编译: CONFIG_$cfg (需要设为 y)"
        MISSING=1
    fi
done

if [ $MISSING -ne 0 ]; then
    echo -e "\n⚠️  存在未开启的virtio驱动，建议重新打开menuconfig启用后再编译！"
else
    echo -e "\n🎉 全部VIRTIO所需驱动已内置开启，可直接编译！"
fi
