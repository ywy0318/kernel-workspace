#!/bin/bash
# 04_06_prepare_uboot_kernel_img.sh
# 内置Image、拷贝dtb、拷贝对应u-boot.bin到每组目录
set -euo pipefail

# ===================== 全局路径配置（上层../01_Uboot） =====================
UBOOT_OUT_GCC="../01_Uboot/output-gcc"
UBOOT_OUT_LLVM="../01_Uboot/output-llvm"
KERNEL_GCC="./output_gcc"
KERNEL_LLVM="./output_llvm"
TMP_MNT="./tmp_mount_ext4"
DIR_OUT_PREFIX="out"
COMB_LIST=(
    "gcc gcc"
    "gcc llvm"
    "llvm gcc"
    "llvm llvm"
)

# ===================== 工具函数 =====================
inject_image_to_rootfs() {
    local rootfs_file="$1"
    local img_src="$2"
    mkdir -p "${TMP_MNT}"
    sudo mount -o loop "${rootfs_file}" "${TMP_MNT}"
    sudo cp "${img_src}" "${TMP_MNT}/Image"
    sudo umount "${TMP_MNT}"
}

# 同时拷贝 dtb + u-boot.bin
copy_uboot_dtb() {
    local uboot_tool="$1"
    local dst_dir="$2"
    local src_dtb src_uboot
    if [[ "${uboot_tool}" == "gcc" ]];then
        src_dtb="${UBOOT_OUT_GCC}/qemu-arm64.dtb"
        src_uboot="${UBOOT_OUT_GCC}/u-boot.bin"
    else
        src_dtb="${UBOOT_OUT_LLVM}/qemu-arm64.dtb"
        src_uboot="${UBOOT_OUT_LLVM}/u-boot.bin"
    fi
    if [ ! -f "${src_dtb}" ] || [ ! -f "${src_uboot}" ];then
        echo "❌ 缺失文件：${src_dtb} / ${src_uboot}"
        exit 1
    fi
    cp "${src_dtb}" "${dst_dir}/qemu-arm64.dtb"
    cp "${src_uboot}" "${dst_dir}/u-boot.bin"
    echo "📋 DTB: ${src_dtb} → ${dst_dir}"
    echo "📋 U-BOOT: ${src_uboot} → ${dst_dir}"
}

# ===================== 主循环 =====================
echo "==================== 批量生成4套组合资源 ===================="
for combo in "${COMB_LIST[@]}";do
    UB_TOOL=$(echo "${combo}" | awk '{print $1}')
    KERN_TOOL=$(echo "${combo}" | awk '{print $2}')
    TARGET_DIR="${DIR_OUT_PREFIX}_${UB_TOOL}_uboot_${KERN_TOOL}_kernel"
    mkdir -p "${TARGET_DIR}"
    echo -e "\n📂 创建目录：${TARGET_DIR}"

    # 1.复制rootfs
    SRC_ROOTFS="./output_${KERN_TOOL}/rootfs/rootfs.ext4"
    DST_ROOTFS="${TARGET_DIR}/rootfs.ext4"
    echo "📋 rootfs: ${SRC_ROOTFS} → ${DST_ROOTFS}"
    cp "${SRC_ROOTFS}" "${DST_ROOTFS}"

    # 2.注入内核Image
    SRC_IMAGE="./output_${KERN_TOOL}/kernel/Image"
    echo "📦 注入Image到rootfs"
    inject_image_to_rootfs "${DST_ROOTFS}" "${SRC_IMAGE}"

    # 3.拷贝dtb + u-boot.bin到当前组合目录
    copy_uboot_dtb "${UB_TOOL}" "${TARGET_DIR}"

    echo "✅ ${TARGET_DIR} 资源完成：rootfs.ext4 qemu-arm64.dtb u-boot.bin"
done

rm -rf "${TMP_MNT}"
echo -e "\n==================== 全部预处理完成 ===================="
ls -d ${DIR_OUT_PREFIX}_*_uboot_*_kernel