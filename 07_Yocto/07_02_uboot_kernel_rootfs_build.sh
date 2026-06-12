#!/bin/bash
set -e

WORK_DIR=~/workspace/07_Yocto
SOURCE_DIR=$WORK_DIR/yocto-sources
BUILD_DIR=$WORK_DIR/build_uboot_kernel_rootfs

# 前置校验
if [ ! -d "$BUILD_DIR/conf" ]; then
    echo "错误：未检测到构建配置，请先执行初始化脚本！"
    exit 1
fi

# 加载Yocto环境
cd "$SOURCE_DIR"
source poky/oe-init-build-env "$BUILD_DIR"

# 打印当前生效的内核锁定版本
echo -e "\n当前生效内核版本配置："
bitbake virtual/kernel -e | grep PREFERRED_VERSION_linux-yocto
bitbake virtual/kernel -e | grep "^PV="

# 兜底清空本地tmp编译临时目录（不碰全局dl/sstate缓存）
rm -rf "${BUILD_DIR}/tmp"

# 清理对应recipe本地编译产物，不会删除全局共享缓存
bitbake virtual/kernel -c cleanall
bitbake linux-libc-headers -c cleanall
bitbake core-image-minimal -c cleanall

echo -e "\n环境加载完成，开始编译 core-image-minimal"
bitbake core-image-minimal

# 输出镜像路径并罗列文件
IMG_OUT="${BUILD_DIR}/tmp/deploy/images/qemuarm64"
echo -e "\n============================================="
echo "✅ 编译全部完成！镜像根输出目录："
echo "${IMG_OUT}"
echo -e "\n📦 目录内全部编译产物列表："
ls -lh "${IMG_OUT}"
echo -e "=============================================\n"
