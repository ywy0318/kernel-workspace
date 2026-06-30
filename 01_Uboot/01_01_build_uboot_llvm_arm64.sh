#!/bin/bash
# LLVM clang aarch64 U-Boot 编译脚本，自动拷贝 qemu-arm64.dtb 并校验
# 先定义当前目录！顺序不能颠倒
CUR_DIR=$(pwd)
# 源码固定路径
UBOOT_SRC_DIR="/home/ubuntu/workspace/01_Uboot/u-boot-v2025.04"
# 输出目录（依赖CUR_DIR，必须后置）
OUTPUT_DIR="${CUR_DIR}/output-llvm"

# 日志时间戳，修复date空格问题
LOG_FILE="./uboot_llvm_build_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo -e "\033[0;34m==================================================\033[0m"
echo -e "\033[0;34m       【LLVM版本】U-Boot aarch64 编译脚本         \033[0m"
echo -e "\033[0;34m==================================================\033[0m"
echo "源码目录: ${UBOOT_SRC_DIR}"
echo "产物输出目录: ${OUTPUT_DIR}"
echo "编译日志文件: ${LOG_FILE}"
echo -e "\033[0;34m==================================================\033[0m"

# 校验源码目录
if [ ! -d "${UBOOT_SRC_DIR}" ];then
    echo -e "\033[0;31m错误：U-Boot源码目录不存在 ${UBOOT_SRC_DIR}\033[0m"
    exit 1
fi

# 创建输出目录（路径正确后正常生成）
mkdir -p "${OUTPUT_DIR}"
echo "已确保输出目录存在: ${OUTPUT_DIR}"

# 进入源码目录
cd "${UBOOT_SRC_DIR}" || exit 1

# 编译环境变量 LLVM
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
export LD=ld.lld
export AR=llvm-ar

# 计时起点
START_TIME=$(date +%s)

# [1/4] 清理旧编译产物
echo -e "\n[1/4] 清理旧编译缓存..."
make clean

# 【已注释defconfig，保留手动menuconfig配置】
# make qemu_arm64_defconfig

# [2/4] 开始编译
echo -e "\n[2/4] 开始编译 U-Boot (arm64 LLVM/clang)..."
make -j$(nproc)

# 计时结束
END_TIME=$(date +%s)
TOTAL_SEC=$((END_TIME - START_TIME))
MIN=$((TOTAL_SEC / 60))
SEC=$((TOTAL_SEC % 60))

# -------------------------- 统一拷贝产物（含dtb）--------------------------
REQUIRED_FILES=("u-boot" "u-boot.bin")
OPTIONAL_SRC_LIST=(
    "u-boot.elf"
    "arch/arm/dts/qemu-arm64.dtb"
)

echo -e "\n[3/4] 拷贝编译产物至输出目录 ${OUTPUT_DIR}"
for item in "${REQUIRED_FILES[@]}" "${OPTIONAL_SRC_LIST[@]}"; do
    src_full="${UBOOT_SRC_DIR}/${item}"
    if [ -f "${src_full}" ];then
        # 单独处理dtb路径，放到输出根目录
        if [[ "${item}" == arch/arm/dts/* ]];then
            dtb_name=$(basename "${item}")
            cp -v "${src_full}" "${OUTPUT_DIR}/${dtb_name}"
        else
            cp -v "${src_full}" "${OUTPUT_DIR}/"
        fi
    else
        echo "跳过不存在文件: ${item}"
    fi
done

# -------------------------- 输出目录产物校验 --------------------------
echo -e "\n[4/4] 产物文件校验与哈希信息"
ALL_SUCCESS=1
OPTIONAL_NAME_LIST=("u-boot.elf" "qemu-arm64.dtb")

# 校验必需文件
for f in "${REQUIRED_FILES[@]}"; do
    f_path="${OUTPUT_DIR}/${f}"
    echo -e "\n--- 必需文件: ${f_path}"
    if [ -f "${f_path}" ];then
        echo "状态: ✅ 文件存在"
        echo "md5sum:    $(md5sum "${f_path}")"
        echo "sha256sum: $(sha256sum "${f_path}")"
    else
        echo -e "\033[0;31m状态: ❌ 文件缺失（必需）\033[0m"
        ALL_SUCCESS=0
    fi
done

# 校验可选文件（包含dtb）
for f in "${OPTIONAL_NAME_LIST[@]}"; do
    f_path="${OUTPUT_DIR}/${f}"
    echo -e "\n--- 可选文件: ${f_path}"
    if [ -f "${f_path}" ];then
        echo "状态: ✅ 文件存在"
        echo "md5sum:    $(md5sum "${f_path}")"
        echo "sha256sum: $(sha256sum "${f_path}")"
    else
        echo "状态: ⚠️ 文件不存在（非必需，不阻断编译）"
    fi
done

# -------------------------- ELF编译器校验 readelf/strings --------------------------
TARGET_ELF="${OUTPUT_DIR}/u-boot"
echo -e "\n==================== 编译器标识校验 ===================="
if [ -f "${TARGET_ELF}" ]; then
    echo "1. readelf .comment 段信息:"
    readelf -p .comment "${TARGET_ELF}"
    echo -e "\n2. 字符串检索编译器特征:"
    strings "${TARGET_ELF}" | grep -i "gcc\|clang\|llvm"
else
    echo -e "\033[0;31m校验失败：输出目录u-boot ELF不存在\033[0m"
fi
echo "========================================================"

# 返回工作目录
cd "${CUR_DIR}" || exit 1

# 编译耗时与最终结果（修复date参数）
echo -e "\n=================================================="
#echo "【LLVM版本】U-Boot 编译结束时间: $(date +%Y-%m-%d %H:%M:%S)"
echo "【LLVM版本】U-Boot 编译结束时间: $(date +%Y-%m-%d\ %H:%M:%S)"
echo "编译总耗时: ${MIN}分${SEC}秒"
echo "=================================================="
if [ ${ALL_SUCCESS} -eq 1 ]; then
    echo -e "\033[0;32m✅ LLVM U-Boot 编译全部完成, 产物已拷贝至 ${OUTPUT_DIR}\033[0m"
    exit 0
else
    echo -e "\033[0;31m❌ LLVM U-Boot 编译失败，必需产物缺失\033[0m"
    exit 1
fi