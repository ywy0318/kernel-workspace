#!/bin/bash
# 06_00_download_buildroot_202502.sh
# 自动下载并解压 Buildroot 2025.02 官方稳定版本
set -e

# ========== 配置区（和你现有工作目录对齐）==========
WORK_BASE="/home/ubuntu/workspace/06_Buildroot"
BR_VERSION="2025.02"
BR_FILE="buildroot-${BR_VERSION}.tar.gz"
BR_URL="https://buildroot.org/downloads/${BR_FILE}"

echo "============================================="
echo "Buildroot 2025.02 下载&解压脚本"
echo "工作目录: ${WORK_BASE}"
echo "下载文件: ${BR_FILE}"
echo "============================================="

# 1. 创建工作目录不存在则新建
mkdir -p "${WORK_BASE}"
cd "${WORK_BASE}"

# 2. 判断压缩包是否已存在，避免重复下载
if [ -f "${BR_FILE}" ]; then
    echo "✅ 本地已存在压缩包 ${BR_FILE}，跳过下载"
else
    echo "🔽 开始从官方源下载 Buildroot ${BR_VERSION}"
    wget --progress=bar:force:noscroll "${BR_URL}"
    echo "✅ 下载完成"
fi

# 3. 判断源码文件夹是否已解压，存在则跳过解压
BR_DIR="buildroot-${BR_VERSION}"
if [ -d "${BR_DIR}" ]; then
    echo "⚠️  源码目录 ${BR_DIR} 已存在，如需全新源码请手动删除该文件夹"
else
    echo "📦 开始解压源码包..."
    tar -zxf "${BR_FILE}"
    echo "✅ 解压完成，源码路径: ${WORK_BASE}/${BR_DIR}"
fi

echo -e "\n============================================="
echo "操作完成！"
echo "源码根目录：${WORK_BASE}/${BR_DIR}"
echo "下一步执行编译脚本 06_02_package_singlethread.sh"
echo "============================================="
