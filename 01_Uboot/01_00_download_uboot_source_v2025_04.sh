#!/bin/bash
# 脚本名：00_01_download_uboot_source_v2025_04.sh
set -e

UBOOT_TAG="v2025.04"
TARGET_DIR="u-boot-${UBOOT_TAG}"

echo "============================================="
echo "开始下载 U-Boot ${UBOOT_TAG} 源码（GitHub原版仓库）"
echo "============================================="

# 目录不存在则完整克隆仓库，存在则拉取远端更新
if [ ! -d "${TARGET_DIR}" ]; then
    git clone https://github.com/u-boot/u-boot.git "${TARGET_DIR}"
    cd "${TARGET_DIR}"
else
    cd "${TARGET_DIR}"
    echo "源码目录已存在，执行远端代码更新拉取"
    git fetch origin
fi

# 检出指定版本标签，新建本地分支
git checkout tags/${UBOOT_TAG} -b ${UBOOT_TAG}-local

echo
echo "============================================="
echo "U-Boot ${UBOOT_TAG} 源码下载&版本检出完成"
echo "源码所在路径：$(pwd)"
echo "============================================="
