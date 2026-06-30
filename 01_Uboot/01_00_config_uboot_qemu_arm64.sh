#!/bin/bash
# 脚本名：01_00_config_uboot_qemu_arm64.sh
# 作用：一键完成U-Boot qemu_arm64 基础配置，开启设备树、ARM64 booti，GCC/LLVM编译共用此配置

# 固定源码路径（和编译脚本保持一致）
UBOOT_SRC_DIR="/home/ubuntu/workspace/01_Uboot/u-boot-v2025.04"
CUR_DIR=$(pwd)

echo -e "\033[0;34m=============================================\033[0m"
echo -e "\033[0;34m        U-Boot qemu_arm64 一键配置脚本        \033[0m"
echo -e "\033[0;34m=============================================\033[0m"

# 校验源码目录是否存在
if [ ! -d "${UBOOT_SRC_DIR}" ]; then
    echo -e "\033[0;31m错误：U-Boot源码目录不存在 ${UBOOT_SRC_DIR}\033[0m"
    exit 1
fi

# 进入源码目录
cd "${UBOOT_SRC_DIR}" || exit 1
echo "当前源码目录：$(pwd)"

# 步骤1：加载默认defconfig
echo -e "\n[1/3] 加载 qemu_arm64_defconfig 基础配置"
make qemu_arm64_defconfig

# 步骤2：自动开启两个必选配置（无需手动menuconfig）
echo -e "\n[2/3] 自动开启设备树、ARM64 booti 支持"
# 开启设备树支持
make scripts/config --enable CONFIG_OF_CONTROL
# 开启ARM64 booti命令支持
make scripts/config --enable CONFIG_CMD_BOOTI

# 步骤3：保存配置并打印生效状态
echo -e "\n[3/3] 配置写入 .config，校验开关状态"
echo "=== 设备树支持开关状态 ==="
grep CONFIG_OF_CONTROL .config
echo "=== ARM64 booti 命令开关状态 ==="
grep CONFIG_CMD_BOOTI .config

# 返回工作目录
cd "${CUR_DIR}"
echo -e "\n\033[0;32m✅ 配置完成！.config 已生成，GCC/LLVM编译脚本可直接复用\033[0m"
echo "源码配置文件路径：${UBOOT_SRC_DIR}/.config"