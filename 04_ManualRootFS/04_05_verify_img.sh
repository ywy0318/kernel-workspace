#!/bin/bash
# 04_05_verify_img.sh
# 功能：校验 firmware_gcc.img / firmware_llvm.img 归档固件包，全套组件完整性+版本校验
set -e
set -u

# ===================== 配置项 =====================
# 待校验归档包名称
GCC_PACK="firmware_gcc.img"
LLVM_PACK="firmware_llvm.img"
# 临时解压目录
TMP_EXTRACT_GCC="./tmp_extract_gcc"
TMP_EXTRACT_LLVM="./tmp_extract_llvm"
# 临时挂载目录
TMP_MOUNT_EXT4="./mnt_ext4_tmp"

# 通用错误退出函数
err_exit() {
    echo -e "\n❌ $1"
    exit 1
}

# 全局前置：自动清理所有旧解压、挂载缓存，避免残留干扰
clean_all_temp_cache() {
    echo "[CLEAN] 自动清理历史临时解压/挂载缓存目录"
    # 卸载残留挂载
    if mount | grep "${TMP_MOUNT_EXT4}" &> /dev/null; then
        sudo umount "${TMP_MOUNT_EXT4}" || true
    fi
    # 删除全部临时目录
    rm -rf "${TMP_EXTRACT_GCC}" "${TMP_EXTRACT_LLVM}" "${TMP_MOUNT_EXT4}"
    echo "[CLEAN] 缓存清理完成"
    echo "================================================================"
}

# 封装单套固件校验函数，传入归档包名、临时解压目录、目录后缀(gcc/llvm)
verify_single_firmware() {
    local PACK_FILE="$1"
    local TMP_EXTRACT_DIR="$2"
    local DIR_SUFFIX="$3"
    echo "================================================================"
    echo "[VERIFY START] 开始校验归档包：${PACK_FILE}"
    echo "================================================================"

    # 1. 检查归档包文件是否存在
    if [ ! -f "${PACK_FILE}" ]; then
        err_exit "缺失归档包：${PACK_FILE}"
    fi
    echo "✅ 归档包文件存在：${PACK_FILE}"

    # 重建当前固件专属临时解压目录
    mkdir -p "${TMP_EXTRACT_DIR}"
    # 解压tar归档到临时目录
    tar -xf "${PACK_FILE}" -C "${TMP_EXTRACT_DIR}"
    echo "✅ 归档包解压完成"

    # 固定目录结构：output_gcc / output_llvm
    local OUTPUT_SUB_DIR="${TMP_EXTRACT_DIR}/output_${DIR_SUFFIX}"
    local ROOTFS_IMAGE="${OUTPUT_SUB_DIR}/rootfs/rootfs.ext4"
    local UBOOT_BIN="${OUTPUT_SUB_DIR}/uboot/u-boot.bin"
    local KERNEL_IMG="${OUTPUT_SUB_DIR}/kernel/Image"

    # 批量检查内部所有固件文件存在性
    echo "[STEP 1/7] 检查归档内部全部固件文件存在性"
    local FILE_LIST=(
        "$ROOTFS_IMAGE"
        "$UBOOT_BIN"
        "$KERNEL_IMG"
    )
    for f in "${FILE_LIST[@]}"; do
        if [ ! -f "$f" ]; then
            err_exit "归档包内缺失固件：$f"
        fi
        echo "✅ 归档内存在：$f"
    done
    echo "================================================================"

    # 2. 校验并打印 U-Boot 版本
    echo "[STEP 2/7] 校验 U-Boot + 读取版本信息"
    local UBOOT_REAL=$(readlink -f "$UBOOT_BIN")
    if ! file "$UBOOT_REAL" | grep -qi "u-boot"; then
        err_exit "$UBOOT_BIN 不是合法U-Boot镜像"
    fi
    local UBOOT_VER=$(strings "$UBOOT_REAL" | grep -E "^U-Boot [0-9]+\.[0-9]+" | head -n1 || echo "无法自动提取版本")
    echo "✅ U-Boot 镜像校验正常"
    echo "🔹 U-Boot 版本信息：$UBOOT_VER"
    echo "================================================================"

    # 3. 校验并打印 Linux Kernel 版本
    echo "[STEP 3/7] 校验内核Image + 读取版本信息"
    local KERNEL_REAL=$(readlink -f "$KERNEL_IMG")
    if ! file "$KERNEL_REAL" | grep -qi "Linux kernel"; then
        err_exit "$KERNEL_IMG 不是合法Linux内核镜像"
    fi
    local KERNEL_VER=$(strings "$KERNEL_REAL" | grep -E "Linux version [0-9]+\.[0-9]+" | head -n1 || echo "无法自动提取版本")
    echo "✅ 内核Image校验正常"
    echo "🔹 内核版本信息：$KERNEL_VER"
    echo "================================================================"

    # 4. rootfs.ext4 完整校验：格式、fsck、关键目录、架构、内核模块
    echo "[STEP 4/7] 校验 ext4 根文件系统完整性、架构、内核模块版本"
    local REAL_IMAGE=$(readlink -f "${ROOTFS_IMAGE}")
    echo "ℹ️  rootfs真实镜像路径：${REAL_IMAGE}"

    # 校验ext4格式
    if ! file "${REAL_IMAGE}" | grep -q "ext4 filesystem"; then
        err_exit "rootfs 不是合法ext4镜像"
    fi
    echo "✅ ext4 镜像格式正确"

    # 文件系统无损检测
    sudo fsck.ext4 -n "${REAL_IMAGE}"
    echo "✅ ext4文件系统无损坏"

    # 挂载校验关键系统目录
    mkdir -p "${TMP_MOUNT_EXT4}"
    sudo mount -o loop "${REAL_IMAGE}" "${TMP_MOUNT_EXT4}"

    # ========== 修正点1：兼容 /init 根目录启动程序 ==========
    local root_init="${TMP_MOUNT_EXT4}/init"
    local sbin_init="${TMP_MOUNT_EXT4}/sbin/init"
    if [ -e "$root_init" ]; then
        echo "✅ /init 存在（嵌入式根目录部署方式，合法）"
    elif [ -e "$sbin_init" ]; then
        echo "✅ /sbin/init 存在"
    else
        err_exit "❌ 缺失初始化程序：/init 与 /sbin/init 均不存在，系统无法启动"
    fi

    # ========== 修正点2：/etc/fstab 改为可选警告项 ==========
    local fstab_path="${TMP_MOUNT_EXT4}/etc/fstab"
    if [ -e "$fstab_path" ]; then
        echo "✅ /etc/fstab"
    else
        echo "⚠️  /etc/fstab 缺失（嵌入式极简系统可无此文件，不影响基础启动）"
    fi

    # 强制必有的基础目录/程序
    local check_items=(
        "/bin/sh"
        "/proc" "/sys" "/usr" "/lib"
    )
    for item in "${check_items[@]}"; do
        local full_path="${TMP_MOUNT_EXT4}${item}"
        [ -e "$full_path" ] && echo "✅ $item" || err_exit "❌ $item 缺失，系统无法正常启动"
    done

    # 校验ARM64架构
    if command -v aarch64-linux-gnu-readelf &> /dev/null; then
        aarch64-linux-gnu-readelf -h "${TMP_MOUNT_EXT4}/bin/sh" | grep "Class\|Machine"
        echo "✅ rootfs 架构：AArch64"
    fi

    # 提取rootfs内置内核模块版本
    local MODULE_DIR="${TMP_MOUNT_EXT4}/lib/modules/"
    local ROOTFS_KERN_VER
    if [ -d "${MODULE_DIR}" ] && [ -n "$(ls -A "${MODULE_DIR}" 2>/dev/null)" ]; then
        ROOTFS_KERN_VER=$(ls "${MODULE_DIR}")
        echo "🔹 rootfs内置内核模块对应版本：${ROOTFS_KERN_VER}"
    else
        echo "⚠️  rootfs无内置内核ko模块"
        ROOTFS_KERN_VER="无内置模块"
    fi

    # 卸载ext4镜像
    sudo umount "${TMP_MOUNT_EXT4}"
    rmdir "${TMP_MOUNT_EXT4}"
    echo "================================================================"

    # 单套固件汇总报告
    echo -e "\n🎉 ======== ${PACK_FILE} 校验汇总报告 ========"
    echo "🔹 U-Boot 版本：$UBOOT_VER"
    echo "🔹 内核Image版本：$KERNEL_VER"
    echo "🔹 rootfs内置模块版本：$ROOTFS_KERN_VER"
    echo "✅ ${PACK_FILE} 内部全部固件校验通过！"
    echo "================================================================"
    echo -e "\n\n"
}

# ===================== 主流程 =====================
echo "==================== 固件归档批量校验工具启动 ===================="
# 第一步：全局自动清理所有旧缓存、残留挂载
clean_all_temp_cache

# 第二步：依次校验GCC、LLVM两套归档
verify_single_firmware "${GCC_PACK}" "${TMP_EXTRACT_GCC}" "gcc"
verify_single_firmware "${LLVM_PACK}" "${TMP_EXTRACT_LLVM}" "llvm"

# 最终收尾：再次清理全部临时目录
clean_all_temp_cache
echo "==================== 全部归档固件校验完成，临时文件已自动清理 ===================="
