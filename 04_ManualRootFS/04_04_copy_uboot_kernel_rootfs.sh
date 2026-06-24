#!/bin/bash
set -e
set -u

# ===================== 固定路径（与你本地目录完全匹配） =====================
# U-Boot 源目录
UBOOT_GCC_SRC="../01_Uboot/output-gcc"
UBOOT_LLVM_SRC="../01_Uboot/output-llvm"
# Linux 内核源目录
KERNEL_GCC_SRC="../02_LinuxKernel/build-gcc"
KERNEL_LLVM_SRC="../02_LinuxKernel/build-llvm"
# 根文件系统镜像
ROOTFS_IMG="${PWD}/rootfs.ext4"
# 输出目录
OUT_GCC="${PWD}/output_gcc"
OUT_LLVM="${PWD}/output_llvm"
# ==========================================================================

echo "============================================="
echo "04_04_copy_uboot_kernel_rootfs.sh 一键拷贝 GCC + LLVM 全套固件"
echo "============================================="

# -------------------------- 全局前置校验所有源文件 --------------------------
echo "[1/6] 全局校验全部 GCC/LLVM 源文件完整性"
# GCC Uboot 校验
if [ ! -f "${UBOOT_GCC_SRC}/u-boot.bin" ] || [ ! -f "${UBOOT_GCC_SRC}/u-boot" ]; then
    echo "ERROR: GCC U-Boot 文件缺失，请先编译uboot-gcc"
    exit 1
fi
# LLVM Uboot 校验
if [ ! -f "${UBOOT_LLVM_SRC}/u-boot.bin" ] || [ ! -f "${UBOOT_LLVM_SRC}/u-boot" ]; then
    echo "ERROR: LLVM U-Boot 文件缺失，请先编译uboot-llvm"
    exit 1
fi
# GCC Kernel 校验
if [ ! -f "${KERNEL_GCC_SRC}/Image" ]; then
    echo "ERROR: GCC Linux Image 内核缺失，请先编译gcc内核"
    exit 1
fi
# LLVM Kernel 校验
if [ ! -f "${KERNEL_LLVM_SRC}/Image" ]; then
    echo "ERROR: LLVM Linux Image 内核缺失，请先编译llvm内核"
    exit 1
fi
# rootfs 校验
if [ ! -f "${ROOTFS_IMG}" ]; then
    echo "ERROR: 当前目录缺失 rootfs.ext4 根文件系统镜像"
    exit 1
fi
echo "✅ 全部源文件校验通过"
echo

# -------------------------- 处理 GCC 固件目录 --------------------------
echo "[2/6] 清理并重建 output_gcc 目录"
rm -rf "${OUT_GCC}"
mkdir -p "${OUT_GCC}/uboot" "${OUT_GCC}/kernel" "${OUT_GCC}/rootfs"

echo "[3/6] 拷贝 GCC U-Boot、内核、rootfs"
cp "${UBOOT_GCC_SRC}/u-boot.bin" "${UBOOT_GCC_SRC}/u-boot" "${OUT_GCC}/uboot/"
cp "${KERNEL_GCC_SRC}/Image" "${OUT_GCC}/kernel/"
cp "${ROOTFS_IMG}" "${OUT_GCC}/rootfs/"
echo "✅ GCC 全套文件拷贝完成"
echo

# -------------------------- 处理 LLVM 固件目录 --------------------------
echo "[4/6] 清理并重建 output_llvm 目录"
rm -rf "${OUT_LLVM}"
mkdir -p "${OUT_LLVM}/uboot" "${OUT_LLVM}/kernel" "${OUT_LLVM}/rootfs"

echo "[5/6] 拷贝 LLVM U-Boot、内核、rootfs"
cp "${UBOOT_LLVM_SRC}/u-boot.bin" "${UBOOT_LLVM_SRC}/u-boot" "${OUT_LLVM}/uboot/"
cp "${KERNEL_LLVM_SRC}/Image" "${OUT_LLVM}/kernel/"
cp "${ROOTFS_IMG}" "${OUT_LLVM}/rootfs/"
echo "✅ LLVM 全套文件拷贝完成"
echo

# -------------------------- 输出两套固件哈希校验 --------------------------
echo "[6/6] 输出文件完整性哈希校验"
echo "============================================="
echo "=============== GCC 固件校验 ==============="
echo "-- U-Boot --"
md5sum "${OUT_GCC}/uboot/"*
sha256sum "${OUT_GCC}/uboot/"*
echo "-- Linux Image --"
md5sum "${OUT_GCC}/kernel/Image"
sha256sum "${OUT_GCC}/kernel/Image"
echo "-- rootfs.ext4 --"
md5sum "${OUT_GCC}/rootfs/rootfs.ext4"
sha256sum "${OUT_GCC}/rootfs/rootfs.ext4"

echo "============================================="
echo "=============== LLVM 固件校验 ==============="
echo "-- U-Boot --"
md5sum "${OUT_LLVM}/uboot/"*
sha256sum "${OUT_LLVM}/uboot/"*
echo "-- Linux Image --"
md5sum "${OUT_LLVM}/kernel/Image"
sha256sum "${OUT_LLVM}/kernel/Image"
echo "-- rootfs.ext4 --"
md5sum "${OUT_LLVM}/rootfs/rootfs.ext4"
sha256sum "${OUT_LLVM}/rootfs/rootfs.ext4"

echo "============================================="
echo "全部拷贝操作执行完毕"
echo "GCC输出目录：${OUT_GCC}"
echo "LLVM输出目录：${OUT_LLVM}"
