#!/bin/bash
# 04_build_bash_static.sh
# 功能：交叉编译 aarch64-linux-gnu 静态 bash（不依赖任何 deb 包）
# 依赖：gcc-aarch64-linux-gnu 工具链

set -e
set -u

# ---------- 可配置区 ----------
BASH_VERSION="5.2.32"
ROOTFS_DIR="${PWD}/rootfs"
# --------------------------------

echo "[04] 开始交叉编译 bash-${BASH_VERSION} (aarch64 真静态)..."

# 1. 检查工具链
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "❌ 请先安装工具链：sudo apt install gcc-aarch64-linux-gnu"
    exit 1
fi

# 2. 创建临时目录
TMP_DIR="./tmp_build_bash"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}"

# 3. 下载 bash 源码（存在就不重下）
SRC_TAR="bash-${BASH_VERSION}.tar.gz"
if [ -f "${SRC_TAR}" ]; then
    echo "✅ 源码包已存在，跳过下载：${SRC_TAR}"
else
    echo "下载 bash 源码..."
    wget "https://ftp.gnu.org/gnu/bash/${SRC_TAR}"
fi

# 4. 解压
tar -xf "${SRC_TAR}"
cd "bash-${BASH_VERSION}"

# 5. 配置：aarch64 + 真静态 + 无依赖
# --enable-static-link：强制静态链接
# --disable-pie：关闭PIE，避免动态解释器
# --disable-shared：不链接动态库
# --without-bash-malloc：用系统malloc，避免静态符号问题
./configure \
    CC=aarch64-linux-gnu-gcc \
    --host=aarch64-linux-gnu \
    --enable-static \
    --enable-static-link \
    --disable-shared \
    --disable-pie \
    --without-bash-malloc \
    --prefix="$(pwd)/install"

# 6. 编译 + 安装到临时目录
make -j$(nproc)
make install

# 7. 拷贝到 rootfs/bin
mkdir -p "${ROOTFS_DIR}/bin"
cp install/bin/bash "${ROOTFS_DIR}/bin/"
chmod +x "${ROOTFS_DIR}/bin/bash"

# 8. 创建 sh 软链接
ln -sf bash "${ROOTFS_DIR}/bin/sh"

# 9. 回到工作目录并清理
cd ../..
#rm -rf "${TMP_DIR}"

echo "[04] ✅ 编译完成！"
echo "--- 验证是否为真静态 ---"
file "${ROOTFS_DIR}/bin/bash"
echo "--- 检查是否有动态解释器（无输出=纯静态）---"
aarch64-linux-gnu-readelf -l "${ROOTFS_DIR}/bin/bash" | grep interpreter
