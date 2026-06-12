#!/bin/bash
# build_uboot_arm64.sh

# 保存当前目录
CUR_DIR=$(pwd)

# 进入源码目录
cd u-boot-2023.04 || { echo "目录不存在，退出"; exit 1; }

# 配置交叉编译环境
export ARCH=arm
export CROSS_COMPILE=aarch64-linux-gnu-

# 加载配置
echo "[1/3] 加载 qemu_arm64_defconfig..."
make qemu_arm64_defconfig

# 编译
echo "[2/3] 开始编译 U-Boot (arm64)..."
make -j$(nproc)

# 检查关键文件是否生成
echo "[3/3] 计算关键文件 MD5..."
for f in u-boot u-boot.bin u-boot.elf; do
    if [ -f "$f" ]; then
        echo "  $f:"
        md5sum "$f"
    else
        echo "  $f: 不存在"
    fi
done

# 回到原目录
cd "$CUR_DIR" || exit
echo "已回到原目录: $(pwd)"
