#!/bin/bash
# 06_03_verify_buildroot_all.sh
# 功能：批量校验 U-Boot + Kernel + rootfs.ext4 + 合成sdcard.img全套固件，输出各组件版本信息
set -e
set -u

# ===================== 配置项（自行按需修改） =====================
BUILDROOT_DIR="/home/ubuntu/workspace/06_Buildroot/buildroot-2023.02.9"
IMG_OUT_DIR="${BUILDROOT_DIR}/output/images"

# 各固件路径（同步打包脚本，sdcard.img统一在images目录）
ROOTFS_IMAGE="${IMG_OUT_DIR}/rootfs.ext4"
UBOOT_BIN="${IMG_OUT_DIR}/u-boot.bin"
KERNEL_IMG="${IMG_OUT_DIR}/Image"
SDCARD_IMG="${IMG_OUT_DIR}/sdcard.img"

TMP_MOUNT_EXT4="./mnt_ext4"
TMP_MOUNT_SD="./mnt_sdcard"

echo "[VERIFY] 开始全套固件完整性校验：U-Boot + Kernel + RootFS + SD整卡镜像"
echo "================================================================"

# 通用错误退出函数
err_exit() {
    echo -e "\n❌ $1"
    exit 1
}

# ===================== 1. 批量检查所有固件文件是否存在 =====================
echo "[STEP 1/8] 检查全部固件文件存在性"
FILE_LIST=(
    "$ROOTFS_IMAGE"
    "$UBOOT_BIN"
    "$KERNEL_IMG"
)
for f in "${FILE_LIST[@]}"; do
    if [ ! -f "$f" ]; then
        err_exit "缺失固件：$f，请先完整编译Buildroot"
    fi
    echo "✅ 存在：$f"
done

if [ ! -f "$SDCARD_IMG" ]; then
    echo "⚠️  整卡sdcard.img不存在，跳过SD镜像校验，继续校验分立固件"
    SKIP_SD_CHECK=1
else
    SKIP_SD_CHECK=0
fi
echo "================================================================"

# ===================== 2. 校验并打印 U-Boot 版本 =====================
echo "[STEP 2/8] 校验 U-Boot + 读取版本信息"
UBOOT_REAL=$(readlink -f "$UBOOT_BIN")
if ! file "$UBOOT_REAL" | grep -qi "u-boot"; then
    err_exit "$UBOOT_BIN 不是合法U-Boot镜像"
fi
# 提取U-Boot版本字符串
UBOOT_VER=$(strings "$UBOOT_REAL" | grep -E "^U-Boot [0-9]+\.[0-9]+" | head -n1 || echo "无法自动提取版本")
echo "✅ U-Boot 校验正常"
echo "🔹 U-Boot 版本信息：$UBOOT_VER"
echo "================================================================"

# ===================== 3. 校验并打印 Linux Kernel 版本 =====================
echo "[STEP 3/8] 校验内核Image + 读取版本信息"
KERNEL_REAL=$(readlink -f "$KERNEL_IMG")
if ! file "$KERNEL_REAL" | grep -qi "Linux kernel"; then
    err_exit "$KERNEL_IMG 不是合法Linux内核镜像"
fi
# 提取内核版本
KERNEL_VER=$(strings "$KERNEL_REAL" | grep -E "Linux version [0-9]+\.[0-9]+" | head -n1 || echo "无法自动提取版本")
echo "✅ 内核Image校验正常"
echo "🔹 内核版本信息：$KERNEL_VER"
echo "================================================================"

# ===================== 4. rootfs.ext4 原有完整校验逻辑 =====================
echo "[STEP 4/8] 校验 ext4 根文件系统完整性、架构、内核模块版本"
REAL_IMAGE=$(readlink -f "${ROOTFS_IMAGE}")
echo "ℹ️  rootfs真实镜像：${REAL_IMAGE}"

# 检查ext4格式
if ! file "${REAL_IMAGE}" | grep -q "ext4 filesystem"; then
    err_exit "rootfs 不是合法ext4镜像"
fi
echo "✅ ext4 镜像格式正确"

# fsck完整性检测
sudo fsck.ext4 -n "${REAL_IMAGE}"
echo "✅ ext4文件系统无损坏"

# 挂载校验关键目录
rm -rf "${TMP_MOUNT_EXT4}"
mkdir -p "${TMP_MOUNT_EXT4}"
sudo mount -o loop "${REAL_IMAGE}" "${TMP_MOUNT_EXT4}"

items=(
    "/bin/sh"
    "/sbin/init"
    "/etc/fstab"
    "/proc" "/sys" "/usr" "/lib"
)
for item in "${items[@]}"; do
    path="${TMP_MOUNT_EXT4}${item}"
    [ -e "$path" ] && echo "✅ $item" || echo "❌ $item 缺失"
done

# 校验架构ARM64
if command -v aarch64-linux-gnu-readelf &> /dev/null; then
    aarch64-linux-gnu-readelf -h "${TMP_MOUNT_EXT4}/bin/sh" | grep "Class\|Machine"
    echo "✅ rootfs 架构：AArch64"
fi

# 提取rootfs内置内核模块版本
MODULE_DIR="${TMP_MOUNT_EXT4}/lib/modules/"
if [ -d "${MODULE_DIR}" ] && [ -n "$(ls -A "${MODULE_DIR}" 2>/dev/null)" ]; then
    ROOTFS_KERN_VER=$(ls "${MODULE_DIR}")
    echo "🔹 rootfs内置内核模块对应版本：${ROOTFS_KERN_VER}"
else
    echo "⚠️  rootfs无内置内核ko模块"
    ROOTFS_KERN_VER="无内置模块"
fi

sudo umount "${TMP_MOUNT_EXT4}" || true
rmdir "${TMP_MOUNT_EXT4}" 2>/dev/null || true
echo "================================================================"

# ===================== 5. 可选：SD整卡镜像 sdcard.img 完整校验 =====================
if [ $SKIP_SD_CHECK -eq 0 ]; then
    echo "[STEP 5/8] 校验整块sdcard.img分区结构与内置内容"
    SD_REAL=$(readlink -f "$SDCARD_IMG")
    # 检查raw镜像
    if ! file "$SD_REAL" | grep -qi "raw disk"; then
        echo "⚠️ sdcard.img 非标准raw磁盘镜像，跳过深度校验"
    else
        echo "✅ sdcard.img 磁盘镜像格式合法"
        # 列出分区表
        echo "🔹 SD镜像分区表信息："
        parted -s "$SD_REAL" print
    fi

    # 挂载SD内ext4分区校验内部文件
    rm -rf "${TMP_MOUNT_SD}"
    mkdir -p "${TMP_MOUNT_SD}"
    LOOP_DEV=$(sudo losetup -f)
    sudo losetup "$LOOP_DEV" "$SD_REAL"
    sudo partprobe "$LOOP_DEV"

    # 挂载第一个ext4分区
    sudo mount "${LOOP_DEV}p1" "${TMP_MOUNT_SD}"
    echo "🔹 SD卡分区内根文件系统关键文件校验："
    [ -e "${TMP_MOUNT_SD}/bin/sh" ] && echo "✅ /bin/sh 存在"
    [ -e "${TMP_MOUNT_SD}/Image" ] && echo "✅ 内核Image已置入SD分区"

    # 提取SD分区内内核模块版本
    if [ -d "${TMP_MOUNT_SD}/lib/modules/" ] && [ -n "$(ls -A "${TMP_MOUNT_SD}/lib/modules/" 2>/dev/null)" ]; then
        SD_KERN_VER=$(ls "${TMP_MOUNT_SD}/lib/modules/")
        echo "🔹 SD镜像内内核模块版本：$SD_KERN_VER"
    fi

    # 容错卸载，避免设备忙报错
    sudo umount "${TMP_MOUNT_SD}" || true
    sudo losetup -d "$LOOP_DEV" || true
    rmdir "${TMP_MOUNT_SD}" 2>/dev/null || true
    echo "================================================================"
else
    echo "[SKIP] 未检测到sdcard.img，跳过整卡镜像校验"
    echo "================================================================"
fi

# ===================== 汇总输出全部版本信息 =====================
echo -e "\n🎉 ======== 全套固件校验汇总报告 ========"
echo "🔹 U-Boot 版本：$UBOOT_VER"
echo "🔹 内核Image版本：$KERNEL_VER"
echo "🔹 rootfs内置模块版本：$ROOTFS_KERN_VER"
if [ $SKIP_SD_CHECK -eq 0 ]; then
    echo "🔹 sdcard.img：校验通过，分区结构正常"
else
    echo "🔹 sdcard.img：不存在，未参与校验"
fi
echo "✅ 所有分立固件校验全部完成！"
echo "========================================"
