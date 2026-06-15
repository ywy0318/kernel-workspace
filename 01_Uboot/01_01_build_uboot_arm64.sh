#!/bin/bash
# 脚本名：01_01_build_uboot_arm64.sh

# 保存当前目录
CUR_DIR=$(pwd)

# 进入源码目录
UBOOT_SRC_DIR="/home/ubuntu/workspace/01_Uboot/u-boot-v2025.04"
cd "$UBOOT_SRC_DIR" || { echo -e "\033[0;31m错误：无法进入U-Boot源码目录 $UBOOT_SRC_DIR\033[0m"; exit 1; }

# 配置交叉编译环境
export ARCH=arm
export CROSS_COMPILE=aarch64-linux-gnu-

# 记录编译开始时间
START_TIME=$(date +%s)
echo -e "\n=================================================="
echo "U-Boot 编译开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="

# 清理旧编译产物
echo "[1/4] 清理旧编译缓存..."
make clean

# 加载配置
echo "[2/4] 加载 qemu_arm64_defconfig..."
make qemu_arm64_defconfig

# 编译
echo "[3/4] 开始编译 U-Boot (arm64)..."
make -j$(nproc)

# 记录编译结束时间并计算耗时
END_TIME=$(date +%s)
ELAPSED_SEC=$((END_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED_SEC / 60))
ELAPSED_REMAIN_SEC=$((ELAPSED_SEC % 60))

# 检查关键文件、打印路径、计算 MD5 & SHA256
echo -e "\n[4/4] 产物文件校验与路径信息"
# 必需文件（失败条件）
REQUIRED_FILES=("u-boot" "u-boot.bin")
# 可选文件（仅提示，不影响成功状态）
OPTIONAL_FILES=("u-boot.elf")

ALL_SUCCESS=1

# 先检查必需文件
for f in "${REQUIRED_FILES[@]}"; do
    FILE_FULLPATH="${UBOOT_SRC_DIR}/${f}"
    echo -e "\n文件路径: ${FILE_FULLPATH}"
    if [ -f "$f" ]; then
        echo "  状态: 文件存在"
        echo "  md5sum:    $(md5sum "$f")"
        echo "  sha256sum: $(sha256sum "$f")"
    else
        echo -e "\033[0;31m  状态: 文件不存在！（必需文件缺失）\033[0m"
        ALL_SUCCESS=0
    fi
done

# 再检查可选文件（u-boot.elf）
for f in "${OPTIONAL_FILES[@]}"; do
    FILE_FULLPATH="${UBOOT_SRC_DIR}/${f}"
    echo -e "\n文件路径: ${FILE_FULLPATH}"
    if [ -f "$f" ]; then
        echo "  状态: 文件存在"
        echo "  md5sum:    $(md5sum "$f")"
        echo "  sha256sum: $(sha256sum "$f")"
    else
        echo "  状态: 文件不存在（非必需，不影响启动）"
    fi
done

# 列出当前目录所有文件
echo -e "\n============================================="
echo "U-Boot 产物目录文件列表: ${UBOOT_SRC_DIR}"
echo "============================================="
ls -l

# 回到原目录
cd "$CUR_DIR" || exit

# 最终状态提示与编译耗时统计
echo -e "\n=================================================="
echo "U-Boot 编译结束时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "编译总耗时：${ELAPSED_MIN}分${ELAPSED_REMAIN_SEC}秒"
echo "=================================================="

if [ $ALL_SUCCESS -eq 1 ]; then
    echo -e "\033[0;32m✅ U-Boot 编译全部完成，必需产物已生成\033[0m"
else
    echo -e "\033[0;31m❌ U-Boot 编译失败，必需产物缺失\033[0m"
    exit 1
fi
