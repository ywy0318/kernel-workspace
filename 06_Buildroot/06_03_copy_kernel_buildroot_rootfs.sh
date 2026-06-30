#!/bin/bash
set -e
set -u

# ====================== 路径配置区（按需修改） ======================
# 手动编译内核目录（GCC / LLVM 两套）
KERNEL_GCC_SRC="../02_LinuxKernel/build-gcc"
KERNEL_LLVM_SRC="../02_LinuxKernel/build-llvm"

# Buildroot 编译输出镜像目录
BUILDROOT_IMG_DIR="${PWD}/buildroot-2025.02/output/images"
# Buildroot 生成的 ext4 根文件系统镜像
ROOTFS_EXT4="${BUILDROOT_IMG_DIR}/rootfs.ext4"
# 备用 ext2（如果存在）
ROOTFS_EXT2="${BUILDROOT_IMG_DIR}/rootfs.ext2"

# 输出固件目录（存放 gcc/llvm 成套固件）
OUT_GCC="${PWD}/output_gcc"
OUT_LLVM="${PWD}/output_llvm"
# ==================================================================

echo "====================================================="
echo "06_03_copy_kernel_buildroot_rootfs.sh"
echo "拷贝 GCC/LLVM 自研内核 + Buildroot 生成 rootfs.ext4/ext2"
echo "自动过滤软链接，仅拷贝真实实体文件，防止镜像依赖失效"
echo "====================================================="

# -------------------------- 1. 前置源文件校验 --------------------------
echo "[1/5] 校验内核、Buildroot 文件系统镜像源文件"
# 校验 GCC 内核 Image
if [ ! -f "${KERNEL_GCC_SRC}/Image" ]; then
    echo "ERROR: GCC 内核 Image 不存在：${KERNEL_GCC_SRC}/Image"
    exit 1
fi
# 校验 LLVM 内核 Image
if [ ! -f "${KERNEL_LLVM_SRC}/Image" ]; then
    echo "ERROR: LLVM 内核 Image 不存在：${KERNEL_LLVM_SRC}/Image"
    exit 1
fi
# 校验 ext4 镜像（必须存在）
if [ ! -f "${ROOTFS_EXT4}" ]; then
    echo "ERROR: Buildroot rootfs.ext4 不存在，请先执行 06_01_build_multithread.sh"
    exit 1
fi
# ext2 可选，不存在仅警告
if [ ! -f "${ROOTFS_EXT2}" ]; then
    echo "WARNING: rootfs.ext2 未生成，仅分发 rootfs.ext4"
fi
echo "✅ 全部源文件校验通过"
echo

# -------------------------- 通用拷贝函数：忽略软链接 --------------------------
# 参数1：源文件路径；参数2：目标目录
copy_file_no_symlink() {
    local src="$1"
    local dst_dir="$2"
    mkdir -p "${dst_dir}"
    # -L 跟随链接会复制源，改用 --copy-contents 只拿实体文件，跳过符号链接本身
    find "${src}" -maxdepth 0 -type f -exec cp --copy-contents {} "${dst_dir}/" \;
}

# -------------------------- 2. 处理 GCC 固件包 --------------------------
echo "[2/5] 清理并重建 output_gcc 目录"
rm -rf "${OUT_GCC}"
mkdir -p "${OUT_GCC}/kernel" "${OUT_GCC}/rootfs"

echo "[3/5] 拷贝 GCC 内核 Image + Buildroot 文件系统镜像"
# 拷贝内核（跳过软链接，复制真实二进制）
copy_file_no_symlink "${KERNEL_GCC_SRC}/Image" "${OUT_GCC}/kernel"
# 拷贝 ext4 根文件系统
copy_file_no_symlink "${ROOTFS_EXT4}" "${OUT_GCC}/rootfs"
# ext2 存在则一并拷贝
[ -f "${ROOTFS_EXT2}" ] && copy_file_no_symlink "${ROOTFS_EXT2}" "${OUT_GCC}/rootfs"
echo "✅ GCC 固件拷贝完成"
echo

# -------------------------- 3. 处理 LLVM 固件包 --------------------------
echo "[4/5] 清理并重建 output_llvm 目录"
rm -rf "${OUT_LLVM}"
mkdir -p "${OUT_LLVM}/kernel" "${OUT_LLVM}/rootfs"

echo "[5/5] 拷贝 LLVM 内核 Image + Buildroot 文件系统镜像"
copy_file_no_symlink "${KERNEL_LLVM_SRC}/Image" "${OUT_LLVM}/kernel"
copy_file_no_symlink "${ROOTFS_EXT4}" "${OUT_LLVM}/rootfs"
[ -f "${ROOTFS_EXT2}" ] && copy_file_no_symlink "${ROOTFS_EXT2}" "${OUT_LLVM}/rootfs"
echo "✅ LLVM 固件拷贝完成"
echo

# -------------------------- 4. 完整哈希校验（防拷贝损坏） --------------------------
echo "====================================================="
echo "================ GCC 固件哈希校验 ================"
echo "--- Linux Kernel Image ---"
md5sum "${OUT_GCC}/kernel/Image"
sha256sum "${OUT_GCC}/kernel/Image"
echo "--- rootfs.ext4 ---"
md5sum "${OUT_GCC}/rootfs/rootfs.ext4"
sha256sum "${OUT_GCC}/rootfs/rootfs.ext4"
if [ -f "${OUT_GCC}/rootfs/rootfs.ext2" ]; then
echo "--- rootfs.ext2 ---"
md5sum "${OUT_GCC}/rootfs/rootfs.ext2"
sha256sum "${OUT_GCC}/rootfs/rootfs.ext2"
fi

echo "====================================================="
echo "================ LLVM 固件哈希校验 ================"
echo "--- Linux Kernel Image ---"
md5sum "${OUT_LLVM}/kernel/Image"
sha256sum "${OUT_LLVM}/kernel/Image"
echo "--- rootfs.ext4 ---"
md5sum "${OUT_LLVM}/rootfs/rootfs.ext4"
sha256sum "${OUT_LLVM}/rootfs/rootfs.ext4"
if [ -f "${OUT_LLVM}/rootfs/rootfs.ext2" ]; then
echo "--- rootfs.ext2 ---"
md5sum "${OUT_LLVM}/rootfs/rootfs.ext2"
sha256sum "${OUT_LLVM}/rootfs/rootfs.ext2"
fi

echo "====================================================="
echo "全部拷贝任务完成！"
echo "GCC成套固件目录：${OUT_GCC}"
echo "LLVM成套固件目录：${OUT_LLVM}"
echo "说明：拷贝时自动跳过软链接，仅复制实体二进制/镜像文件，无链接失效风险"