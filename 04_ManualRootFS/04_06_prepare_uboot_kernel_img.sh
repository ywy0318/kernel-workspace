#!/bin/bash
# 04_06_prepare_uboot_kernel_img.sh
# 功能：批量生成4套组合镜像，方案1：Image内置进rootfs.ext4
# 组合：uboot(gcc/llvm) × kernel(gcc/llvm)

set -euo pipefail

# ========== 全局路径配置（和你现有脚本对齐，无需修改）==========
# GCC产物根目录
OUT_GCC="./output_gcc"
# LLVM产物根目录
OUT_LLVM="./output_llvm"
# 临时挂载目录
TMP_MNT="./tmp_mount_ext4"
# 4套输出目录前缀
DIR_PREFIX="out"

# 定义四组组合：uboot工具链,kernel工具链
COMBINATIONS=(
    "gcc gcc"
    "gcc llvm"
    "llvm gcc"
    "llvm llvm"
)

# ========== 函数：挂载镜像并拷贝Image ==========
copy_image_to_rootfs() {
    local rootfs_file="$1"
    local kernel_img_path="$2"

    # 校验内核Image存在
    if [ ! -f "${kernel_img_path}" ];then
        echo "❌ 内核文件缺失：${kernel_img_path}"
        exit 1
    fi
    # 校验rootfs镜像存在
    if [ ! -f "${rootfs_file}" ];then
        echo "❌ rootfs镜像缺失：${rootfs_file}"
        exit 1
    fi

    # 创建临时挂载点
    mkdir -p "${TMP_MNT}"
    echo "🔧 挂载镜像 ${rootfs_file} 到 ${TMP_MNT}"
    sudo mount -o loop "${rootfs_file}" "${TMP_MNT}"

    # 拷贝内核Image到镜像根目录
    echo "📦 拷贝内核Image: ${kernel_img_path} → ${TMP_MNT}/Image"
    sudo cp "${kernel_img_path}" "${TMP_MNT}/Image"

    # 卸载镜像，释放锁
    echo "🔌 卸载镜像..."
    sudo umount "${TMP_MNT}"
    echo "✅ 镜像处理完成: ${rootfs_file}"
    echo "-----------------------------------------"
}

# ========== 主逻辑遍历四组组合 ==========
echo "==================== 开始批量生成4套镜像组合 ===================="
for combo in "${COMBINATIONS[@]}";do
    # 拆分uboot工具链、kernel工具链
    UB_TOOL=$(echo $combo | awk '{print $1}')
    KERN_TOOL=$(echo $combo | awk '{print $2}')

    # 生成输出目录名
    TARGET_DIR="${DIR_PREFIX}_${UB_TOOL}_uboot_${KERN_TOOL}_kernel"
    mkdir -p "${TARGET_DIR}"
    echo "📂 创建工作目录: ${TARGET_DIR}"

    # 原始rootfs路径
    SRC_ROOTFS="./output_${KERN_TOOL}/rootfs/rootfs.ext4"
    # 目标rootfs路径（复制一份到独立目录）
    DST_ROOTFS="${TARGET_DIR}/rootfs.ext4"

    # 复制原始rootfs镜像
    echo "📋 复制rootfs镜像: ${SRC_ROOTFS} → ${DST_ROOTFS}"
    cp "${SRC_ROOTFS}" "${DST_ROOTFS}"

    # 对应内核Image路径
    SRC_IMAGE="./output_${KERN_TOOL}/kernel/Image"

    # 执行挂载+拷贝Image
    copy_image_to_rootfs "${DST_ROOTFS}" "${SRC_IMAGE}"
done

# 清理临时挂载目录
rm -rf "${TMP_MNT}"
echo "==================== 全部4套镜像处理完毕 ===================="
echo "生成目录清单："
ls -d out_*_uboot_*_kernel