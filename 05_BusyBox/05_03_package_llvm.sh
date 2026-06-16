#!/bin/bash
# 05_03_package_llvm.sh
# LLVM固件打包：24字节头部(3组小端uint64)，拼接u-boot+Image+rootfs.cpio.gz生成system_llvm.img
set -e
set -u

# ===================== 路径配置区 =====================
UBOOT_BIN="/home/ubuntu/workspace/01_Uboot/u-boot-v2025.04/u-boot.bin"
KERNEL_IMAGE="/home/ubuntu/workspace/02_LinuxKernel/build-llvm/Image"
ROOTFS_CPIO="/home/ubuntu/workspace/05_BusyBox/rootfs.cpio.gz"

OUT_DIR="./output_llvm"
FINAL_IMG="${OUT_DIR}/system_llvm.img"
# ======================================================

# 小端64位无符号整数写入函数
write_u64_le() {
    local num="$1"
    # 依次输出低字节到高字节（小端）
    printf "\\$(printf '%02x' $((num & 0xff)))"
    printf "\\$(printf '%02x' $(((num >> 8) & 0xff)))"
    printf "\\$(printf '%02x' $(((num >> 16) & 0xff)))"
    printf "\\$(printf '%02x' $(((num >> 24) & 0xff)))"
    printf "\\$(printf '%02x' $(((num >> 32) & 0xff)))"
    printf "\\$(printf '%02x' $(((num >> 40) & 0xff)))"
    printf "\\$(printf '%02x' $(((num >> 48) & 0xff)))"
    printf "\\$(printf '%02x' $(((num >> 56) & 0xff)))"
}

echo "==================== LLVM 镜像打包开始 ===================="
# 重建输出目录
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

# 拷贝原始固件文件留存
echo "[1/5] 拷贝基础固件文件至输出目录"
cp "${UBOOT_BIN}" "${OUT_DIR}/"
cp "${KERNEL_IMAGE}" "${OUT_DIR}/"
cp "${ROOTFS_CPIO}" "${OUT_DIR}/"

# 获取三段文件真实字节长度
UBOOT_RAW_SIZE=$(stat -c "%s" "${OUT_DIR}/u-boot.bin")
KERNEL_RAW_SIZE=$(stat -c "%s" "${OUT_DIR}/Image")
ROOTFS_RAW_SIZE=$(stat -c "%s" "${OUT_DIR}/rootfs.cpio.gz")
echo "[2/5] 采集分段长度："
echo "    u-boot.bin: ${UBOOT_RAW_SIZE} 字节"
echo "    Image内核: ${KERNEL_RAW_SIZE} 字节"
echo "    rootfs.cpio.gz: ${ROOTFS_RAW_SIZE} 字节"

# 初始化镜像并写入24字节头部（3×8字节小端uint64）
> "${FINAL_IMG}"
write_u64_le "${UBOOT_RAW_SIZE}" >> "${FINAL_IMG}"
write_u64_le "${KERNEL_RAW_SIZE}" >> "${FINAL_IMG}"
write_u64_le "${ROOTFS_RAW_SIZE}" >> "${FINAL_IMG}"

# 依次拼接三段二进制固件
echo "[3/5] 写入u-boot.bin至镜像"
cat "${OUT_DIR}/u-boot.bin" >> "${FINAL_IMG}"
echo "[4/5] 写入内核Image至镜像"
cat "${OUT_DIR}/Image" >> "${FINAL_IMG}"
echo "[5/5] 写入rootfs.cpio.gz至镜像"
cat "${OUT_DIR}/rootfs.cpio.gz" >> "${FINAL_IMG}"

# 输出镜像校验和
echo -e "\n===== ${FINAL_IMG} 校验信息 ====="
echo "MD5SUM:"
md5sum "${FINAL_IMG}"
echo "SHA256SUM:"
sha256sum "${FINAL_IMG}"

echo -e "\n🎉 LLVM打包完成，输出目录：${OUT_DIR}"
ls -lh "${OUT_DIR}"
