#!/bin/bash
# 04_07_prepare_separate_kernel_disk.sh
# 方案2：内核独立virtio磁盘，双磁盘架构预处理脚本
# 组合维度：uboot编译工具链(gcc/llvm) + kernel编译工具链(gcc/llvm)
set -euo pipefail

# ===================== 全局路径配置（与现有工程对齐，无需修改） =====================
# 原始编译输出目录
OUT_GCC="./output_gcc"
OUT_LLVM="./output_llvm"
# 输出目录前缀
DIR_OUT_PREFIX="build_uboot_kernel_pair"
# 四组组合：uboot工具链 kernel工具链
COMBINATION_LIST=(
    "gcc gcc"
    "gcc llvm"
    "llvm gcc"
    "llvm llvm"
)

# ===================== 批量处理主逻辑 =====================
echo "==================== 开始批量生成4套双磁盘镜像组合 ===================="
for combo in "${COMBINATION_LIST[@]}"; do
    # 拆分uboot编译工具链、内核编译工具链
    UB_TOOL=$(echo "${combo}" | awk '{print $1}')
    KERN_TOOL=$(echo "${combo}" | awk '{print $2}')

    # 生成独立目录名
    TARGET_DIR="${DIR_OUT_PREFIX}_ub${UB_TOOL}_kern${KERN_TOOL}"
    mkdir -p "${TARGET_DIR}"
    echo -e "\n📂 创建独立工作目录：${TARGET_DIR}"

    # 1. 复制根文件系统镜像（第一块virtio盘：rootfs）
    SRC_ROOTFS="./output_${KERN_TOOL}/rootfs/rootfs.ext4"
    DST_ROOTFS="${TARGET_DIR}/rootfs.ext4"
    if [ ! -f "${SRC_ROOTFS}" ]; then
        echo "❌ 缺失根文件系统镜像：${SRC_ROOTFS}"
        exit 1
    fi
    echo "📋 拷贝根文件系统：${SRC_ROOTFS} → ${DST_ROOTFS}"
    cp "${SRC_ROOTFS}" "${DST_ROOTFS}"

    # 2. 复制内核Image（第二块独立virtio盘，纯内核文件，方案2专用）
    SRC_IMAGE="./output_${KERN_TOOL}/kernel/Image"
    DST_IMAGE="${TARGET_DIR}/kernel_Image.raw"
    if [ ! -f "${SRC_IMAGE}" ]; then
        echo "❌ 缺失内核Image文件：${SRC_IMAGE}"
        exit 1
    fi
    echo "📦 拷贝独立内核镜像：${SRC_IMAGE} → ${DST_IMAGE}"
    cp "${SRC_IMAGE}" "${DST_IMAGE}"

    echo "✅ ${TARGET_DIR} 资源准备完成（rootfs.ext4 + kernel_Image.raw）"
done

echo -e "\n==================== 全部4套双磁盘资源生成完毕 ===================="
echo "生成目录清单："
ls -d ${DIR_OUT_PREFIX}_*
echo -e "\n使用说明："
echo "1. rootfs.ext4 对应 qemu -drive 第0块virtio磁盘（根文件系统）"
echo "2. kernel_Image.raw 对应 qemu -drive 第1块virtio磁盘（独立内核）"
echo "3. U-Boot加载命令：virtio scan; ext4load virtio 1:1 0x40000000 Image; booti 0x40000000"