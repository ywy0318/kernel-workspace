#!/bin/bash
set -u

DROPBEAR_VER="2024.84"
ROOTFS_DIR="${PWD}/rootfs"
TMP_BUILD_DROPBEAR="./tmp_build_dropbear"

# 交叉编译工具链
CROSS=aarch64-linux-gnu-
CC="${CROSS}gcc"
AR="${CROSS}ar"
LD="${CROSS}ld"

# 前置校验rootfs是否存在
[ ! -d "${ROOTFS_DIR}" ] && echo "ERROR: 请先执行 04_01_prepare_rootfs.sh 生成rootfs目录" && exit 1

echo "============================================="
echo "开始编译 dropbear-${DROPBEAR_VER} SSH工具集"
echo "============================================="
mkdir -p "${TMP_BUILD_DROPBEAR}"
cd "${TMP_BUILD_DROPBEAR}"

DB_TAR="dropbear-${DROPBEAR_VER}.tar.bz2"
# 本地存在源码包则跳过下载
if [ -f "${DB_TAR}" ]; then
    echo "检测到本地已存在 ${DB_TAR}，跳过下载，直接解压编译"
else
    echo "本地无dropbear源码包，从官方原始地址断点续传下载..."
    if ! wget -c https://matt.ucc.asn.au/dropbear/releases/dropbear-2024.84.tar.bz2; then
        echo "WARNING: dropbear 源码下载失败，跳过SSH套件编译"
        cd ../..
        exit 0
    fi
fi

tar -xf "${DB_TAR}"
cd "dropbear-${DROPBEAR_VER}"

# 核心修复：强制关闭密码认证，消除crypt()依赖报错
./configure \
    CC="${CC}" \
    AR="${AR}" \
    LD="${LD}" \
    CPPFLAGS="-DDROPBEAR_SVR_PASSWORD_AUTH=0" \
    --host=aarch64-linux-gnu \
    --enable-static \
    --disable-zlib \
    --disable-pam \
    --disable-shadow

make PROGRAMS="dropbear dbclient scp" -j$(nproc)

# 复制二进制到rootfs/bin
cp dropbear "${ROOTFS_DIR}/bin/"
cp dbclient "${ROOTFS_DIR}/bin/ssh"
cp scp "${ROOTFS_DIR}/bin/scp"
chmod +x "${ROOTFS_DIR}/bin/dropbear" "${ROOTFS_DIR}/bin/ssh" "${ROOTFS_DIR}/bin/scp"

cd ../..
echo "dropbear 编译部署完成：sshd / ssh / scp 已写入rootfs"
echo "⚠️ 已禁用密码登录，仅支持SSH密钥登录，无libcrypt依赖"
echo
