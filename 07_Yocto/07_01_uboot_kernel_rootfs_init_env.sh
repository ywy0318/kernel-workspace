#!/bin/bash
set -e

# 全局路径定义
WORK_DIR=~/workspace/07_Yocto
SOURCE_DIR=$WORK_DIR/yocto-sources
# 构建目录（单个构建实例，可随时删除）
BUILD_DIR=$WORK_DIR/build_uboot_kernel_rootfs
# 【修改】全局公共缓存，放到项目根目录，脱离build目录
SHARE_DL=$WORK_DIR/dl_shared
SHARE_SSTATE=$WORK_DIR/sstate_shared
CONF_DIR=$BUILD_DIR/conf

# 批量创建目录
mkdir -p \
    "$SOURCE_DIR" \
    "$BUILD_DIR" \
    "$SHARE_DL" \
    "$SHARE_SSTATE" \
    "$CONF_DIR"

echo "===== 目录创建完成 ====="
echo "构建主目录：$BUILD_DIR"
echo "全局共享下载缓存：$SHARE_DL"
echo "全局共享编译缓存：$SHARE_SSTATE"

# bblayers.conf：仅不存在时生成
BBLAYERS_CONF="$CONF_DIR/bblayers.conf"
if [ ! -f "$BBLAYERS_CONF" ]; then
    cat > "$BBLAYERS_CONF" <<'EOF'
BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  /home/ubuntu/workspace/07_Yocto/yocto-sources/poky/meta \
  /home/ubuntu/workspace/07_Yocto/yocto-sources/poky/meta-poky \
  /home/ubuntu/workspace/07_Yocto/yocto-sources/poky/meta-yocto-bsp \
  /home/ubuntu/workspace/07_Yocto/yocto-sources/meta-openembedded/meta-oe \
  /home/ubuntu/workspace/07_Yocto/yocto-sources/meta-openembedded/meta-python \
  /home/ubuntu/workspace/07_Yocto/yocto-sources/meta-openembedded/meta-networking \
"
EOF
    echo "新生成层配置文件：$BBLAYERS_CONF"
else
    echo "层配置已存在，跳过写入"
fi

# local.conf：仅不存在时生成模板
#LOCAL_CONF="$LOCAL_CONF=$CONF_DIR/local.conf"
LOCAL_CONF="$CONF_DIR/local.conf"
LOCAL_CONF="$CONF_DIR/local.conf"
if [ ! -f "$LOCAL_CONF" ]; then
    cat > "$LOCAL_CONF" <<'EOF'
# 基础编译配置
MACHINE = "qemuarm64"
DISTRO = "poky"
IMAGE_FSTYPES = "tar.gz ext4 cpio.gz"
INHERIT += "rm_work"

KERNEL_IMAGETYPE = "Image"
UBOOT_MACHINE = "qemu_arm64_defconfig"

BB_NUMBER_THREADS = "${@oe.utils.cpu_count()}"
PARALLEL_MAKE = "-j ${@oe.utils.cpu_count()}"

# 【修改】全局绝对路径缓存，不再绑定当前build
DL_DIR = "/home/ubuntu/workspace/07_Yocto/dl_shared"
SSTATE_DIR = "/home/ubuntu/workspace/07_Yocto/sstate_shared"

FETCHCMD_wget = "/usr/bin/wget --tries=10 --timeout=60 -c"
GITFETCHTIMEOUT = "300"
BB_GIT_RETRY_COUNT = "5"

# 下方由用户手动添加国内镜像源、内核版本配置，脚本不会修改
# UNINATIVE_URL = "https://mirrors.ustc.edu.cn/yocto/releases/uninative/"
# PREMIRRORS:prepend = ""
# MIRRORS = ""
EOF
    echo "新生成local.conf模板：$LOCAL_CONF"
else
    echo "local.conf已存在，保留手动配置，跳过写入"
fi

echo -e "\n初始化全部完成！"
echo "✅ 缓存全局独立存放，删除build目录不会丢失下载/编译缓存"
echo "后续执行编译脚本即可正常构建"
