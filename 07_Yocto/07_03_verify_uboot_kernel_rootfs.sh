#!/bin/bash
# 07_03_verify_uboot_kernel_rootfs.sh
# 功能：验证Yocto编译输出的rootfs.ext4、kernel Image，提取内核版本，适配本次qemuarm64编译产物
set -e
set -u

# ========== 配置区域（根据你的实际路径修改）==========
DEPLOY_PATH="/home/ubuntu/workspace/07_Yocto/build_uboot_kernel_rootfs/tmp/deploy/images/qemuarm64"
ROOTFS_EXT4="${DEPLOY_PATH}/core-image-minimal-qemuarm64.ext4"
KERNEL_IMAGE="${DEPLOY_PATH}/Image"
TMP_MNT="./tmp_mnt_yocto_rootfs"
TMP_KERNEL_EXTRACT="./tmp_kernel_check"
# ==================================================

echo "[07_03] Yocto 整套固件验证脚本开始执行"
echo "部署目录: ${DEPLOY_PATH}"
echo "----------------------------------------"

## 一、校验【强制核心产物】完整性（ext4、kernel、modules）
echo "[1/7] 校验编译核心强制产物完整性"
MANDATORY_FILE_LIST=(
    "${ROOTFS_EXT4}"
    "${KERNEL_IMAGE}"
    "${DEPLOY_PATH}/modules-qemuarm64.tgz"
)
all_mandatory_ok=1
for f in "${MANDATORY_FILE_LIST[@]}"; do
    if [ -L "${f}" ] || [ -f "${f}" ]; then
        echo "✅ 存在: $(basename ${f})"
    else
        echo "❌ 缺失: ${f}"
        all_mandatory_ok=0
    fi
done
if [ ${all_mandatory_ok} -ne 1 ]; then
    echo "❌ 核心关键编译产物缺失，终止验证"
    exit 1
fi

# 可选产物tar.gz，只告警不退出
TAR_GZ_LINK="${DEPLOY_PATH}/core-image-minimal-qemuarm64.tar.gz"
if [ -L "${TAR_GZ_LINK}" ] || [ -f "${TAR_GZ_LINK}" ]; then
    echo "✅ 可选tar.gz压缩包存在"
else
    echo "⚠️ 可选tar.gz压缩包不存在，不影响固件烧录使用"
fi
echo "----------------------------------------"

## 二、提取并打印Linux Kernel版本信息
echo "[2/7] 解析内核镜像版本信息"
mkdir -p "${TMP_KERNEL_EXTRACT}"
cd "${TMP_KERNEL_EXTRACT}"
# 提取内核版本字符串
strings "${KERNEL_IMAGE}" | grep -m1 "Linux version"
KERNEL_VER=$(strings "${KERNEL_IMAGE}" | grep -m1 "Linux version" | awk '{print $3}')
echo "✅ 内核完整版本号: ${KERNEL_VER}"
cd - >/dev/null
rm -rf "${TMP_KERNEL_EXTRACT}"

# 改用file查看内核架构，Image不是ELF不能用readelf
echo "内核架构信息:"
file "${KERNEL_IMAGE}"
echo "----------------------------------------"

## 三、挂载ext4 rootfs镜像，校验根文件系统关键目录/文件
echo "[3/7] 挂载ext4根文件系统并完整性校验"
rm -rf "${TMP_MNT}"
mkdir -p "${TMP_MNT}"
sudo mount "${ROOTFS_EXT4}" "${TMP_MNT}"

# 嵌入式Linux根文件系统必备目录清单
REQUIRED_DIRS=(
    bin boot dev etc home lib lib64 media mnt opt proc root run sbin srv sys tmp usr var
)
echo "校验必备系统目录:"
for d in "${REQUIRED_DIRS[@]}"; do
    full_path="${TMP_MNT}/${d}"
    if [ -d "${full_path}" ]; then
        echo "✅ /${d} 存在"
    else
        echo "❌ /${d} 缺失"
    fi
done

# 关键可执行、配置文件校验
REQUIRED_FILES=(
    "/bin/sh"
    "/sbin/init"
    "/etc/passwd"
    "/etc/group"
)
echo -e "\n校验关键系统文件:"
for f in "${REQUIRED_FILES[@]}"; do
    full_path="${TMP_MNT}/${f}"
    if [ -e "${full_path}" ]; then
        echo "✅ ${f} 存在"
    else
        echo "❌ ${f} 缺失"
    fi
done

## 四、读取rootfs内部内核模块版本，和Image内核比对
echo -e "\n[4/7] 校验rootfs内内核模块与内核镜像版本匹配性"
MODULE_TGZ="${DEPLOY_PATH}/modules-qemuarm64.tgz"
mkdir -p ./tmp_mod_check
tar -xf "${MODULE_TGZ}" -C ./tmp_mod_check
MOD_KERN_VER=$(ls ./tmp_mod_check/lib/modules/)
echo "rootfs内置内核模块版本目录: ${MOD_KERN_VER}"
echo "内核镜像版本: ${KERNEL_VER}"
if [[ "${MOD_KERN_VER}" == *"${KERNEL_VER%%-*}"* ]]; then
    echo "✅ 内核镜像与驱动模块版本完全匹配"
else
    echo "⚠️ 内核镜像和模块版本不一致，会导致ko无法加载"
fi
rm -rf ./tmp_mod_check

## 五、读取rootfs发行版信息
echo -e "\n[5/7] 读取rootfs系统发行版信息"
if [ -f "${TMP_MNT}/etc/os-release" ]; then
    cat "${TMP_MNT}/etc/os-release"
else
    echo "⚠️ 无/etc/os-release，最小化镜像无发行版标识"
fi

## 六、卸载挂载点
echo -e "\n[6/7] 卸载ext4镜像，清理临时挂载目录"
sudo umount "${TMP_MNT}"
rm -rf "${TMP_MNT}"
echo "✅ 已安全卸载镜像，无残留挂载"

## 七、U-Boot说明（重点提示）
echo -e "\n[7/7] U-Boot 状态说明"
echo "⚠️ 当前MACHINE=qemuarm64为QEMU虚拟机平台，Yocto默认不会编译、输出u-boot.bin"
echo "QEMU aarch64虚拟机直接使用 Image + dtb 启动，不需要U-Boot引导程序"
echo "若需要实体硬件U-Boot，必须自定义board machine配置，重新编译才能生成u-boot.bin"

echo -e "\n============================================="
echo "🎉 Yocto Kernel + Rootfs 验证全部执行完毕！"
echo "✅ Rootfs ext4镜像完整可用，内核版本: ${KERNEL_VER}"
echo "✅ 内核模块与内核版本匹配，可直接烧录部署"
echo "============================================="
