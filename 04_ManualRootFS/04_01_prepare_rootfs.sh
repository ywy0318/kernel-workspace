#!/bin/bash
set -e
set -u

# ===================== 配置常量 =====================
BASH_VERSION="5.2.32"
ROOTFS_DIR="${PWD}/rootfs"
TMP_BUILD_BASH="./tmp_build_bash"

# 网络固定参数（给后续打包脚本共用）
NET_IP="10.0.2.15"
NET_MASK="255.255.255.0"
NET_GW="10.0.2.2"
DNS1="223.5.5.5"
DNS2="114.114.114.114"
# ====================================================

# 交叉编译器校验
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "ERROR: 缺失 aarch64-linux-gnu-gcc 交叉编译器"
    exit 1
fi
CROSS=aarch64-linux-gnu-

# 前置源码校验
[ ! -f "${PWD}/init.c" ] && echo "ERROR: 缺失 init.c" && exit 1
[ ! -f "${PWD}/net_tools" ] && echo "ERROR: 缺失预编译 net_tools 二进制" && exit 1

# 仅清理rootfs，保留bash临时编译目录（不删除bash缓存包）
echo "============================================="
echo "清理旧 rootfs 目录，保留 bash 编译缓存目录"
rm -rf "${ROOTFS_DIR}"
echo "============================================="
echo

####################################################
# 1、创建完整rootfs目录结构
####################################################
echo "[1/5] 创建 rootfs 目录结构"
mkdir -p "${ROOTFS_DIR}"/{bin,dev,etc,lib,proc,sys,tmp,var,run,sbin,usr/bin,usr/sbin,etc/init.d}
mkdir -p "${ROOTFS_DIR}/etc/dropbear"
chmod 1777 "${ROOTFS_DIR}/tmp"
echo

####################################################
# 2、编译静态 init
####################################################
echo "[2/5] 交叉编译静态 init"
${CROSS}gcc -static -o "${ROOTFS_DIR}/init" init.c
chmod +x "${ROOTFS_DIR}/init"
echo "init 编译完成"
echo

####################################################
# 3、创建 /dev 基础设备节点
####################################################
echo "[3/5] 创建 /dev/console / /dev/null"
sudo rm -f "${ROOTFS_DIR}/dev/console" "${ROOTFS_DIR}/dev/null"
sudo mknod "${ROOTFS_DIR}/dev/console" c 5 1
sudo mknod "${ROOTFS_DIR}/dev/null"  c 1 3
echo "设备节点创建完成"
echo

####################################################
# 4、编译静态 bash（不删除tmp_build_bash，存在tar包则跳过下载）
####################################################
echo "[4/5] 编译静态 bash-${BASH_VERSION}"
mkdir -p "${TMP_BUILD_BASH}"
cd "${TMP_BUILD_BASH}"

BASH_TAR="bash-${BASH_VERSION}.tar.gz"
# 本地已有源码包则不再重复下载
if [ ! -f "${BASH_TAR}" ]; then
    echo "本地无bash源码包，开始下载..."
    wget https://ftp.gnu.org/gnu/bash/"${BASH_TAR}"
else
    echo "检测到本地已存在 ${BASH_TAR}，跳过下载"
fi

tar -xf "${BASH_TAR}"
cd "bash-${BASH_VERSION}"

./configure \
    CC=${CROSS}gcc \
    --host=aarch64-linux-gnu \
    --enable-static \
    --enable-static-link \
    --disable-shared \
    --disable-pie \
    --without-bash-malloc \
    --prefix="$(pwd)/install"

make -j$(nproc)
make install

cp install/bin/bash "${ROOTFS_DIR}/bin/"
chmod +x "${ROOTFS_DIR}/bin/bash"
ln -sf bash "${ROOTFS_DIR}/bin/sh"

cd ../..
echo "bash 编译完成，缓存目录 tmp_build_bash 已保留"
echo

####################################################
# 5、部署三合一网络工具 net_tools
####################################################
echo "[5/5] 复制预编译 net_tools 至 rootfs/sbin"
cp "${PWD}/net_tools" "${ROOTFS_DIR}/sbin/"
chmod +x "${ROOTFS_DIR}/sbin/net_tools"
echo "基础网络工具部署完成：ifconfig / gw_add / ping"
echo

echo "============================================="
echo "04_01 执行完成，rootfs 基础框架已生成：${ROOTFS_DIR}"
echo "下一步执行 ./04_02_build_dropbear.sh 编译SSH套件"
echo "============================================="
