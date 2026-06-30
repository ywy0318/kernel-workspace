#!/bin/bash
# 脚本名：01_02_build_uboot_llvm_arm64.sh
# LLVM clang aarch64交叉编译U-Boot
# 日志文件定义，每次编译生成带时间戳的日志
LOG_FILE="./uboot_llvm_build_$(date +%Y%m%d_%H%M%S).log"
# 重定向所有输出到日志，同时打印终端
exec > >(tee -a "${LOG_FILE}") 2>&1

# 保存当前目录
CUR_DIR=$(pwd)
# 源码目录
UBOOT_SRC_DIR="/home/ubuntu/workspace/01_Uboot/u-boot-v2025.04"
# LLVM产物输出目录
OUTPUT_DIR="${CUR_DIR}/output-llvm"

# 创建输出目录
mkdir -p "${OUTPUT_DIR}" || { echo -e "\033[0;31m错误：创建LLVM输出目录失败 ${OUTPUT_DIR}\033[0m"; exit 1; }

# 进入源码目录
cd "$UBOOT_SRC_DIR" || { echo -e "\033[0;31m错误：无法进入U-Boot源码目录 $UBOOT_SRC_DIR\033[0m"; exit 1; }

# LLVM arm64编译环境变量
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
export LD=ld.lld
export AR=llvm-ar
export OBJCOPY=llvm-objcopy

# 记录编译开始时间
START_TIME=$(date +%s)
echo -e "\n=================================================="
echo "【LLVM版本】U-Boot 编译开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "产物输出目录：${OUTPUT_DIR}"
echo "=================================================="

# 清理旧编译缓存
echo "[1/4] 清理旧编译缓存..."
make clean

# 加载配置
echo "[2/4] 加载 qemu_arm64_defconfig..."
make qemu_arm64_defconfig
#make virt_aarch64_defconfig
# 自动开启设备树、booti、内置dtb、默认virt设备树
#make scripts/config --enable CONFIG_OF_CONTROL
#make scripts/config --enable CONFIG_CMD_BOOTI
#make scripts/config --enable CONFIG_OF_EMBED
#make scripts/config --set-str CONFIG_DEFAULT_DEVICE_TREE "virt-aarch64"

# 同步更新配置，解决依赖冲突
#make olddefconfig


# 编译
echo "[3/4] 开始编译 U-Boot (arm64 LLVM/clang)..."
#make -j$(nproc)
#make -j$(nproc) CC=clang LD=ld.lld AR=llvm-ar OBJCOPY=llvm-objcopy
make -j$(nproc) \
    HOSTCC=gcc \
    CC="clang --target=aarch64-linux-gnu" \
    LD=ld.lld \
    AR=llvm-ar \
    OBJCOPY=llvm-objcopy
make -j$(nproc) \
    HOSTCC=gcc \
    CC="clang --target=aarch64-linux-gnu" \
    LD=ld.lld \
    AR=llvm-ar \
    OBJCOPY=aarch64-linux-gnu-objcopy  # 新增：强制使用 GNU objcopy
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
        # 拷贝到输出目录
        cp -f "$f" "${OUTPUT_DIR}/"
        echo "  已拷贝至输出目录: ${OUTPUT_DIR}/${f}"
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
        cp -f "$f" "${OUTPUT_DIR}/"
        echo "  已拷贝至输出目录: ${OUTPUT_DIR}/${f}"
    else
        echo "  状态: 文件不存在（非必需，不影响启动）"
    fi
done

# 列出源码目录产物
echo -e "\n============================================="
echo "U-Boot 源码产物目录文件列表: ${UBOOT_SRC_DIR}"
echo "============================================="
ls -l

# 回到工作根目录
cd "$CUR_DIR" || exit

# 输出目录文件列表
echo -e "\n============================================="
echo "LLVM编译产物输出目录: ${OUTPUT_DIR}"
ls -l "${OUTPUT_DIR}"
echo "============================================="
# ===================== 新增：编译器校验 =====================
TARGET_ELF="${OUTPUT_DIR}/u-boot"
if [ -f "${TARGET_ELF}" ]; then
    echo -e "\n==================== 【LLVM编译产物编译器校验】 ===================="
    echo "1. 读取 .comment 段信息:"
    readelf -p .comment "${TARGET_ELF}"
    echo -e "\n2. 字符串检索编译器标识:"
    strings "${TARGET_ELF}" | grep -i "clang\|gcc\|llvm"
    echo "=================================================================="
else
    echo -e "\033[0;31m\n校验失败：输出目录不存在u-boot文件，无法验证编译器\033[0m"
fi
# ==========================================================
# 查看 ELF 头信息，确定编译器/链接器
#readelf -p .comment ./output-llvm/u-boot

# 或者直接用 strings 搜索编译器特征字符串
#strings ./output-llvm/u-boot | grep -i "clang\|gcc\|llvm"
# 最终状态提示与编译耗时统计
echo -e "\n=================================================="
echo "【LLVM版本】U-Boot 编译结束时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "编译总耗时：${ELAPSED_MIN}分${ELAPSED_REMAIN_SEC}秒"
echo "=================================================="

if [ $ALL_SUCCESS -eq 1 ]; then
    echo -e "\033[0;32m✅ LLVM U-Boot 编译全部完成，产物已拷贝至 ${OUTPUT_DIR}\033[0m"
else
    echo -e "\033[0;31m❌ LLVM U-Boot 编译失败，必需产物缺失\033[0m"
    exit 1
fi
