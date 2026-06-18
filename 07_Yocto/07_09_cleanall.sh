#!/bin/bash
set -e

WORK_ROOT=~/workspace/07_Yocto
BUILD_DIR=${WORK_ROOT}/build_uboot_kernel_rootfs

echo "============================================="
echo "开始清理构建临时编译缓存（保留全局dl_shared/sstate_shared）"
echo "构建目录：${BUILD_DIR}"
echo "============================================="

# 校验构建目录是否存在
if [ ! -d "${BUILD_DIR}/conf" ]; then
    echo "警告：未检测到构建配置目录，无需清理"
    cd ${WORK_ROOT}
    exit 0
fi

# 进入构建目录加载Yocto环境
cd ${BUILD_DIR}
source ../yocto-sources/poky/oe-init-build-env .

# 清理内核、u-boot、根文件系统镜像编译产物
echo "1. 清理 linux-yocto / u-boot / core-image-minimal 编译缓存"
bitbake virtual/kernel u-boot core-image-minimal -c cleanall

# 删除本地临时tmp目录（最大的编译临时文件）
echo "2. 删除本地tmp临时编译目录"
rm -rf ./tmp

echo -e "\n✅ 清理完成！仅删除构建内部临时文件，全局下载/预编译缓存保留："
echo "全局源码缓存：${WORK_ROOT}/dl_shared"
echo "全局预编译缓存：${WORK_ROOT}/sstate_shared"

# 强制退回项目根目录
cd ${WORK_ROOT}
echo -e "\n当前工作目录：$(pwd)"
