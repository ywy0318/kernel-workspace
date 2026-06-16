#!/bin/bash
# 05_04_verify_raw_img.sh
# 校验05_03打包生成的 system_gcc.img / system_llvm.img RAW拼接镜像
# 头部24字节小端uint64存储三段长度，无dropbear校验项
set -e
set -u

# ===================== 全局配置 =====================
# 待校验RAW镜像文件名
GCC_RAW_IMG="./output_gcc/system_gcc.img"
LLVM_RAW_IMG="./output_llvm/system_llvm.img"
# 临时解压缓存目录
TMP_GCC_EXTRACT="./tmp_raw_gcc"
TMP_LLVM_EXTRACT="./tmp_raw_llvm"
# 分段拆分临时文件
SPLIT_UBOOT="./tmp_split_uboot.bin"
SPLIT_KERNEL="./tmp_split_Image"
SPLIT_ROOTFS="./tmp_split_rootfs.cpio.gz"

# 错误退出封装
err_exit() {
    echo -e "\n❌ $1"
    exit 1
}

# 全局清理所有临时缓存
clean_all_temp() {
    echo "[CLEAN] 清理全部临时拆分/解压目录"
    rm -rf "${TMP_GCC_EXTRACT}" "${TMP_LLVM_EXTRACT}"
    rm -f "${SPLIT_UBOOT}" "${SPLIT_KERNEL}" "${SPLIT_ROOTFS}"
    echo "[CLEAN] 缓存清理完成"
    echo "====================================================================="
}

# 读取镜像指定偏移8字节小端uint64，返回十进制长度
read_u64_le() {
    local offset="$1"
    # 读取8字节原始十六进制字符串
    local hex_raw=$(xxd -s "${offset}" -l 8 -ps "${RAW_FILE}")
    # 反转字节序：小端转主机大端
    local hex_rev=$(echo "${hex_raw}" | sed -E 's/(..)(..)(..)(..)(..)(..)(..)(..)/\8\7\6\5\4\3\2\1/')
    # 十六进制转十进制输出
    echo $((16#${hex_rev}))
}

# 单镜像校验函数
# 参数：RAW镜像路径、临时解压目录、标识后缀(gcc/llvm)
verify_single_raw() {
    local RAW_FILE="$1"
    local TMP_EXTRACT="$2"
    local TAG="$3"

    echo "====================================================================="
    echo "[VERIFY START] 校验镜像：${RAW_FILE} 【${TAG}编译链】"
    echo "====================================================================="

    # 1. 校验镜像本体文件存在
    if [ ! -f "${RAW_FILE}" ]; then
        err_exit "原始镜像文件不存在：${RAW_FILE}"
    fi
    echo "✅ RAW镜像文件存在：${RAW_FILE}"

    # 重建临时解压目录
    rm -rf "${TMP_EXTRACT}"
    mkdir -p "${TMP_EXTRACT}"

    # --------------------------
    # 步骤1：读取镜像头部24字节分段长度，拆分三段组件（修复字节序）
    # --------------------------
    echo "[STEP 1/8] 读取镜像头部分段长度并拆分组件"
    UBOOT_SIZE=$(read_u64_le 0)
    KERNEL_SIZE=$(read_u64_le 8)
    ROOTFS_SIZE=$(read_u64_le 16)

    echo "镜像内置分段信息："
    echo "    u-boot.bin: ${UBOOT_SIZE} 字节"
    echo "    Image内核: ${KERNEL_SIZE} 字节"
    echo "    rootfs.cpio.gz: ${ROOTFS_SIZE} 字节"

    # dd拆分：跳过头部24字节
    dd if="${RAW_FILE}" of="${SPLIT_UBOOT}" bs=1 skip=24 count="${UBOOT_SIZE}" status=none
    echo "✅ 拆分完成：u-boot.bin"

    local KERNEL_SKIP=$((24 + UBOOT_SIZE))
    dd if="${RAW_FILE}" of="${SPLIT_KERNEL}" bs=1 skip="${KERNEL_SKIP}" count="${KERNEL_SIZE}" status=none
    echo "✅ 拆分完成：内核Image"

    local ROOTFS_SKIP=$((24 + UBOOT_SIZE + KERNEL_SIZE))
    dd if="${RAW_FILE}" of="${SPLIT_ROOTFS}" bs=1 skip="${ROOTFS_SKIP}" count="${ROOTFS_SIZE}" status=none
    echo "✅ 拆分完成：rootfs.cpio.gz"
    echo "====================================================================="

    # --------------------------
    # 步骤2：校验U-Boot合法性 + 提取版本
    # --------------------------
    echo "[STEP 2/8] 校验U-Boot镜像并读取版本"
    if ! file "${SPLIT_UBOOT}" | grep -qi "u-boot"; then
        err_exit "拆分出的u-boot.bin不是合法U-Boot镜像"
    fi
    local UBOOT_VER=$(strings "${SPLIT_UBOOT}" | grep -E "^U-Boot [0-9]+\.[0-9]+" | head -n1 || echo "无法识别版本")
    echo "✅ U-Boot镜像校验通过"
    echo "🔹 U-Boot版本：${UBOOT_VER}"
    echo "====================================================================="

    # --------------------------
    # 步骤3：校验Linux内核Image合法性 + 提取内核版本
    # --------------------------
    echo "[STEP 3/8] 校验内核Image并读取版本"
    if ! file "${SPLIT_KERNEL}" | grep -qi "Linux kernel"; then
        err_exit "拆分出的Image不是合法Linux内核镜像"
    fi
    local KERNEL_VER=$(strings "${SPLIT_KERNEL}" | grep -E "Linux version [0-9]+\.[0-9]+" | head -n1 || echo "无法识别版本")
    echo "✅ 内核Image校验通过"
    echo "🔹 内核版本：${KERNEL_VER}"
    echo "====================================================================="

    # --------------------------
    # 步骤4：校验rootfs.cpio.gz压缩包完整性并解压
    # --------------------------
    echo "[STEP 4/8] 校验rootfs.cpio.gz压缩包完整性"
    gzip -t "${SPLIT_ROOTFS}" || err_exit "rootfs.cpio.gz 压缩包损坏"
    echo "✅ cpio压缩包无损校验通过"

    # 解压cpio到临时目录
    cd "${TMP_EXTRACT}"
    cpio -idmv < ../"${SPLIT_ROOTFS%.gz}" > /dev/null 2>&1
    cd ..
    echo "✅ rootfs完整解压至 ${TMP_EXTRACT}"
    echo "====================================================================="

    # --------------------------
    # 步骤5：校验根文件系统核心启动文件
    # --------------------------
    echo "[STEP 5/8] 校验BusyBox系统核心启动文件"
    local CHECK_BASE=(
        "/bin/busybox"
        "/init"
        "/etc/inittab"
        "/etc/init.d/rcS"
        "/dev/null"
        "/dev/console"
        "/proc"
        "/sys"
        "/tmp"
    )
    for item in "${CHECK_BASE[@]}"; do
        local full="${TMP_EXTRACT}${item}"
        if [ ! -e "${full}" ]; then
            err_exit "根文件系统缺失核心文件：${item}"
        fi
        echo "✅ 存在：${item}"
    done
    echo "====================================================================="

    # --------------------------
    # 步骤6：校验开机脚本rcS：固定IP、telnetd启动配置（移除dropbear检查）
    # --------------------------
    echo "[STEP 6/8] 校验开机脚本rcS：固定IP、telnetd启动配置"
    local RCS_FILE="${TMP_EXTRACT}/etc/init.d/rcS"
    local RCS_CONTENT=$(cat "${RCS_FILE}")

    # 检查固定IP配置关键字
    if ! echo "${RCS_CONTENT}" | grep -q "ifconfig eth0"; then
        err_exit "rcS内未配置网卡静态IP"
    fi
    # 检查telnetd启动
    if ! echo "${RCS_CONTENT}" | grep -q "telnetd"; then
        err_exit "rcS未开启telnet服务"
    fi
    # 检查DNS配置
    if ! echo "${RCS_CONTENT}" | grep -q "nameserver"; then
        echo "⚠️  rcS未配置DNS解析，网络域名访问异常"
    fi

    echo "✅ rcS 固定IP / telnetd 配置完整"
    echo "====================================================================="

    # --------------------------
    # 步骤7：校验root登录账号密码文件
    # --------------------------
    echo "[STEP 7/8] 校验root登录账号passwd+shadow"
    local PASSWD="${TMP_EXTRACT}/etc/passwd"
    local SHADOW="${TMP_EXTRACT}/etc/shadow"
    if [ ! -f "${PASSWD}" ] || ! grep -q "^root:" "${PASSWD}"; then
        err_exit "passwd缺失或无root账号"
    fi
    if [ ! -f "${SHADOW}" ] || ! grep -q "^root:" "${SHADOW}"; then
        err_exit "shadow缺失，远程登录会被拒绝"
    fi
    echo "✅ root登录账号与密码文件完整"
    echo "====================================================================="

    # --------------------------
    # 步骤8：校验BusyBox内置依赖工具（移除dropbear）
    # --------------------------
    echo "[STEP 8/8] 校验BusyBox必备网络工具存在"
    local BUSYBOX_TOOLS=(
        "ifconfig"
        "route"
        "telnetd"
        "scp"
    )
    for tool in "${BUSYBOX_TOOLS[@]}"; do
        if ! "${TMP_EXTRACT}/bin/busybox" --list | grep -q "^${tool}$"; then
            err_exit "BusyBox未编译内置工具：${tool}，远程登录/文件传输失效"
        fi
        echo "✅ busybox内置工具：${tool}"
    done
    echo "====================================================================="

    # --------------------------
    # 单镜像汇总报告（移除SSH描述）
    # --------------------------
    echo -e "\n🎉 ========== ${RAW_FILE} 【${TAG}】校验汇总报告 =========="
    echo "🔹 U-Boot版本：${UBOOT_VER}"
    echo "🔹 Linux内核版本：${KERNEL_VER}"
    echo "🔹 rootfs内置服务：静态IP + Telnet + scp文件传输"
    echo "✅ ${RAW_FILE} 全部组件校验通过！无缺失/损坏项"
    echo "====================================================================="
    echo -e "\n\n"
}

# ===================== 主执行流程 =====================
echo "==================== RAW固件镜像批量校验工具 05_04 ===================="
# 全局前置清理
clean_all_temp

# 依次校验gcc、llvm两套镜像
verify_single_raw "${GCC_RAW_IMG}" "${TMP_GCC_EXTRACT}" "gcc"
verify_single_raw "${LLVM_RAW_IMG}" "${TMP_LLVM_EXTRACT}" "llvm"

# 执行完毕再次清理缓存
clean_all_temp
echo "==================== 全部RAW镜像校验完成，临时文件已清理 ===================="
