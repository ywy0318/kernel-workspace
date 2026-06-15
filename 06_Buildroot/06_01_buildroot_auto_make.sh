#!/bin/bash
set -e

##############################################################################
# 配置区（已修正为绝对路径，避免cd错误）
##############################################################################
# 这里用绝对路径，直接复制你的目录
BUILDROOT_DIR="/home/ubuntu/workspace/06_Buildroot/buildroot-2023.02.9"
ROOTFS_IMG="$BUILDROOT_DIR/output/images/rootfs.ext4"
JOBS=$(nproc)

##############################################################################
# 开始
##############################################################################
echo "============================================================="
echo " Buildroot 一键编译+打包（多核编译 + 干净环境单线程打包）"
echo "============================================================="

# 先检查目录是否存在
if [ ! -d "$BUILDROOT_DIR" ]; then
    echo "❌ 错误：$BUILDROOT_DIR 目录不存在！"
    exit 1
fi

cd "$BUILDROOT_DIR" || { echo "❌ 无法进入目录 $BUILDROOT_DIR"; exit 1; }

# -------------------------- 可选：全量清理 --------------------------
# 下面这行默认注释，需要彻底重建时再打开
# echo "[步骤] make clean（全量清理）"
# make clean
# ---------------------------------------------------------------------

echo -e "\n[1/2] 多线程编译 -j$JOBS"
make -j"$JOBS"

echo -e "\n[2/2] 全新环境单线程打包（避开并发污染）"
# 关键：用绝对路径，避免cd错误
bash -c "
  cd '$BUILDROOT_DIR'
  unset MAKEFLAGS MFLAGS LD_LIBRARY_PATH JOB_SERVER_FIFO
  make -j1
"

# 检查产物
if [ -f "$ROOTFS_IMG" ]; then
    echo -e "\n✅ 成功！"
    echo "镜像路径: $ROOTFS_IMG"
else
    echo -e "\n❌ 打包失败"
    exit 1
fi
