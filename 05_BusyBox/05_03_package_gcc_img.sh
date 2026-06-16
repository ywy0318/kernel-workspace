#!/bin/bash
# 05_03_package_gcc.sh
# GCC固件打包：24字节头部(3组小端uint64)，修复二进制写入bug
set -e
set -u

# ===================== 路径配置区 =====================
UBOOT_BIN="/home/ubuntu/workspace/01_Uboot/u-boot-v2025.04/u-boot.bin"
KERNEL_IMAGE="/home/ubuntu/workspace/02_LinuxKernel/build-gcc/Image"
ROOTFS_CPIO="/home/ubuntu/workspace/05_BusyBox/rootfs.cpio.gz"

OUT_DIR="./output_gcc"
FINAL_IMG="${OUT_DIR}/system_gcc.img"
# ======================================================

# 修复：可靠小端64位无符号整数二进制写入
write_u64_le() {
    local num="$1"
    local bytes=()
    for ((i=0; i<8; i++)); do
        bytes[$i]=$(( (num >> (8*i)) & 0xff ))
    done
    for b in "${bytes[@]}"; do
        printf "%b" "\\x$(printf "%02x" "$b")"
    done
}

echo "==================== GCC 镜像打包开始 ===================="
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

echo "[1/5] 拷贝基础固件文件至输出目录"
cp "${UBOOT_BIN}" "${OUT_DIR}/"
cp "${KERNEL_IMAGE}" "${OUT_DIR}/"
cp "${ROOTFS_CPIO}" "${OUT_DIR}/"

UBOOT_RAW_SIZE=$(stat -c "%s" "${OUT_DIR}/u-boot.bin")
KERNEL_RAW_SIZE=$(stat -c "%s" "${OUT_DIR}/Image")
ROOTFS_RAW_SIZE=$(stat -c "%s" "${OUT_DIR}/rootfs.cpio.gz")
echo "[2/5] 采集分段长度："
echo "    u-boot.bin: ${UBOOT_RAW_SIZE} 字节"
echo "    Image内核: ${KERNEL_RAW_SIZE} 字节"
echo "    rootfs.cpio.gz: ${ROOTFS_RAW_SIZE} 字节"

# 初始化镜像并写入24字节头部
> "${FINAL_IMG}"
write_u64_le "${UBOOT_RAW_SIZE}" >> "${FINAL_IMG}"
write_u64_le "${KERNEL_RAW_SIZE}" >> "${FINAL_IMG}"
write_u64_le "${ROOTFS_RAW_SIZE}" >> "${FINAL_IMG}"

echo "[3/5] 写入u-boot.bin至镜像"
cat "${OUT_DIR}/u-boot.bin" >> "${FINAL_IMG}"
echo "[4/5] 写入内核Image至镜像"
cat "${OUT_DIR}/Image" >> "${FINAL_IMG}"
echo "[5/5] 写入rootfs.cpio.gz至镜像"
cat "${OUT_DIR}/rootfs.cpio.gz" >> "${FINAL_IMG}"

echo -e "\n===== ${FINAL_IMG} 校验信息 ====="
echo "MD5SUM:"
md5sum "${FINAL_IMG}"
echo "SHA256SUM:"
sha256sum "${FINAL_IMG}"

echo -e "\n🎉 GCC打包完成，输出目录：${OUT_DIR}"
ls -lh "${OUT_DIR}"
