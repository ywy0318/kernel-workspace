#!/bin/bash
set -e
set -u

# ===================== 路径常量 统一配置 =====================
# UBoot 输出目录
UBOOT_BUILD_PATH="/home/ubuntu/workspace/01_Uboot/u-boot-v2025.04"
# GCC内核编译输出目录
KERNEL_GCC_PATH="/home/ubuntu/workspace/02_LinuxKernel/build-gcc"
# rootfs镜像路径（当前脚本同目录）
ROOTFS_IMG="${PWD}/rootfs.ext4"
# 输出存放目录
OUTPUT_DIR="${PWD}/output_gcc"
# 最终打包文件名
PACK_NAME="firmware_gcc.img"
# ==========================================================

echo "============================================="
echo "GCC 全套固件打包脚本启动"
echo "============================================="

# 前置文件校验
echo "[1/6] 校验全部依赖文件是否存在"
# Uboot核心镜像
if [ ! -f "${UBOOT_BUILD_PATH}/u-boot.bin" ]; then
    echo "ERROR: 缺失 u-boot.bin 路径: ${UBOOT_BUILD_PATH}/u-boot.bin"
    exit 1
fi
if [ ! -f "${UBOOT_BUILD_PATH}/u-boot" ]; then
    echo "ERROR: 缺失 u-boot 路径: ${UBOOT_BUILD_PATH}/u-boot"
    exit 1
fi
# GCC内核Image
if [ ! -f "${KERNEL_GCC_PATH}/Image" ]; then
    echo "ERROR: 缺失 GCC 内核 Image: ${KERNEL_GCC_PATH}/Image"
    exit 1
fi
# rootfs镜像
if [ ! -f "${ROOTFS_IMG}" ]; then
    echo "ERROR: 缺失 rootfs.ext4 根文件系统镜像: ${ROOTFS_IMG}"
    exit 1
fi
echo "全部依赖文件校验通过"
echo

# 清理旧输出目录，重建干净目录
echo "[2/6] 清理并创建输出目录 ${OUTPUT_DIR}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/uboot"
mkdir -p "${OUTPUT_DIR}/kernel"
mkdir -p "${OUTPUT_DIR}/rootfs"
echo

# 拷贝Uboot文件
echo "[3/6] 拷贝 UBoot 镜像文件"
cp "${UBOOT_BUILD_PATH}/u-boot.bin" "${OUTPUT_DIR}/uboot/"
cp "${UBOOT_BUILD_PATH}/u-boot" "${OUTPUT_DIR}/uboot/"
echo "uboot 文件拷贝完成"
echo

# 拷贝GCC内核镜像
echo "[4/6] 拷贝 GCC 编译 Linux 内核 Image"
cp "${KERNEL_GCC_PATH}/Image" "${OUTPUT_DIR}/kernel/"
echo "gcc kernel 文件拷贝完成"
echo

# 拷贝rootfs镜像
echo "[5/6] 拷贝 rootfs.ext4 根文件系统镜像"
cp "${ROOTFS_IMG}" "${OUTPUT_DIR}/rootfs/"
echo "rootfs 镜像拷贝完成"
echo

# 打包成 .img tar归档文件
echo "[6/6] 将 output_gcc 目录打包为 ${PACK_NAME}"
rm -f "${PACK_NAME}"
tar -cf "${PACK_NAME}" -C "${PWD}" output_gcc
echo "打包完成，归档文件: ${PACK_NAME}"
echo

# 计算并输出校验和
echo "============================================="
echo "===== ${PACK_NAME} 校验摘要信息 ====="
echo "MD5SUM:"
md5sum "${PACK_NAME}"
echo "---------------------------------------------"
echo "SHA256SUM:"
sha256sum "${PACK_NAME}"
echo "============================================="
echo "GCC固件打包流程全部执行完毕"
echo "输出目录: ${OUTPUT_DIR}"
echo "打包归档文件: ${PWD}/${PACK_NAME}"
