#!/bin/bash
set -e
set -u

# ===================== 路径配置区（适配BusyBox根文件系统） =====================
# Linux 内核编译产物目录
KERNEL_GCC_SRC="../02_LinuxKernel/build-gcc"
KERNEL_LLVM_SRC="../02_LinuxKernel/build-llvm"

# BusyBox 根文件系统目录（05_01脚本生成）
BUSYBOX_ROOTFS_DIR="${PWD}/rootfs"
# BusyBox打包后的ext4镜像（如有）
BUSYBOX_ROOTFS_IMG="${PWD}/rootfs.ext4"

# 输出固件目录（和04_04脚本保持一致）
OUT_GCC="${PWD}/output_gcc"
OUT_LLVM="${PWD}/output_llvm"
# ==========================================================================

echo "============================================="
echo "05_03_copy_kernel_busybox_rootfs.sh 拷贝内核+BusyBox根文件系统"
echo "分别分发至 output_gcc / output_llvm（自动跳过/dev设备目录）"
echo "============================================="

# -------------------------- 全局前置校验所有源文件 --------------------------
echo "[1/6] 校验 GCC/LLVM 内核、BusyBox根文件系统源文件"
# GCC 内核校验
if [ ! -f "${KERNEL_GCC_SRC}/Image" ]; then
    echo "ERROR: GCC Linux 内核 Image 缺失，请先编译gcc内核"
    exit 1
fi
# LLVM 内核校验
if [ ! -f "${KERNEL_LLVM_SRC}/Image" ]; then
    echo "ERROR: LLVM Linux 内核 Image 缺失，请先编译llvm内核"
    exit 1
fi
# BusyBox 根文件系统目录校验
if [ ! -d "${BUSYBOX_ROOTFS_DIR}" ]; then
    echo "ERROR: BusyBox 根文件系统目录不存在：${BUSYBOX_ROOTFS_DIR}"
    echo "请先执行 ./05_01_busybox_build_rootfs.sh 生成rootfs目录"
    exit 1
fi
# 校验ext4镜像（可选）
if [ ! -f "${BUSYBOX_ROOTFS_IMG}" ]; then
    echo "WARNING: 未找到rootfs.ext4镜像，仅拷贝rootfs目录文件（跳过/dev）"
fi
echo "✅ 全部源文件校验通过"
echo

# -------------------------- 定义通用拷贝函数（跳过/dev） --------------------------
copy_rootfs_without_dev() {
    local src=$1
    local dst=$2
    # 先拷贝所有文件，排除dev目录
    find "${src}" -maxdepth 1 -mindepth 1 ! -name dev -exec cp -r {} "${dst}/" \;
}

# -------------------------- 处理 GCC 固件目录 --------------------------
echo "[2/6] 清理并重建 output_gcc 目录结构"
rm -rf "${OUT_GCC}"
mkdir -p "${OUT_GCC}/kernel" "${OUT_GCC}/rootfs_dir" "${OUT_GCC}/rootfs_img"

echo "[3/6] 拷贝 GCC 内核 + BusyBox根文件系统（跳过/dev设备）"
# 拷贝内核Image
cp "${KERNEL_GCC_SRC}/Image" "${OUT_GCC}/kernel/"
# 调用函数拷贝rootfs，自动跳过dev
copy_rootfs_without_dev "${BUSYBOX_ROOTFS_DIR}" "${OUT_GCC}/rootfs_dir"
# 拷贝ext4镜像（存在才拷贝）
[ -f "${BUSYBOX_ROOTFS_IMG}" ] && cp "${BUSYBOX_ROOTFS_IMG}" "${OUT_GCC}/rootfs_img/"
echo "✅ GCC 内核+BusyBox根文件系统拷贝完成"
echo

# -------------------------- 处理 LLVM 固件目录 --------------------------
echo "[4/6] 清理并重建 output_llvm 目录结构"
rm -rf "${OUT_LLVM}"
mkdir -p "${OUT_LLVM}/kernel" "${OUT_LLVM}/rootfs_dir" "${OUT_LLVM}/rootfs_img"

echo "[5/6] 拷贝 LLVM 内核 + BusyBox根文件系统（跳过/dev设备）"
cp "${KERNEL_LLVM_SRC}/Image" "${OUT_LLVM}/kernel/"
copy_rootfs_without_dev "${BUSYBOX_ROOTFS_DIR}" "${OUT_LLVM}/rootfs_dir"
[ -f "${BUSYBOX_ROOTFS_IMG}" ] && cp "${BUSYBOX_ROOTFS_IMG}" "${OUT_LLVM}/rootfs_img/"
echo "✅ LLVM 内核+BusyBox根文件系统拷贝完成"
echo

# -------------------------- 两套固件哈希完整性校验 --------------------------
echo "[6/6] 输出文件哈希校验（md5+sha256）"
echo "============================================="
echo "=============== GCC 固件校验 ==============="
echo "-- Linux Image --"
md5sum "${OUT_GCC}/kernel/Image"
sha256sum "${OUT_GCC}/kernel/Image"
echo "-- BusyBox RootFS目录文件（不含/dev） --"
md5sum "${OUT_GCC}/rootfs_dir/"*
sha256sum "${OUT_GCC}/rootfs_dir/"*
if [ -f "${OUT_GCC}/rootfs_img/rootfs.ext4" ];then
echo "-- rootfs.ext4 镜像 --"
md5sum "${OUT_GCC}/rootfs_img/rootfs.ext4"
sha256sum "${OUT_GCC}/rootfs_img/rootfs.ext4"
fi

echo "============================================="
echo "=============== LLVM 固件校验 ==============="
echo "-- Linux Image --"
md5sum "${OUT_LLVM}/kernel/Image"
sha256sum "${OUT_LLVM}/kernel/Image"
echo "-- BusyBox RootFS目录文件（不含/dev） --"
md5sum "${OUT_LLVM}/rootfs_dir/"*
sha256sum "${OUT_LLVM}/rootfs_dir/"*
if [ -f "${OUT_LLVM}/rootfs_img/rootfs.ext4" ];then
echo "-- rootfs.ext4 镜像 --"
md5sum "${OUT_LLVM}/rootfs_img/rootfs.ext4"
sha256sum "${OUT_LLVM}/rootfs_img/rootfs.ext4"
fi

echo "============================================="
echo "拷贝任务全部执行完毕"
echo "GCC固件目录：${OUT_GCC}"
echo "LLVM固件目录：${OUT_LLVM}"
echo "说明：rootfs_dir 已自动剔除/dev设备节点，QEMU启动会自动生成虚拟dev"