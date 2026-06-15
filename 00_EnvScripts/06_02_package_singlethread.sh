#!/bin/bash

BUILDROOT_DIR="buildroot-2023.02.9"
ROOTFS_IMAGE="$BUILDROOT_DIR/output/images/rootfs.ext4"

echo -e "\n===== 强制干净环境单线程打包 =====\n"

# 关键：用 nohup 启动一个完全独立的进程，彻底隔离当前终端的并发环境
nohup bash -c "
  cd $BUILDROOT_DIR
  unset LD_LIBRARY_PATH
  unset MAKEFLAGS
  unset MFLAGS
  unset JOB_SERVER_FIFO
  make -j1
" > build.log 2>&1

# 等待打包完成
wait

# 检查结果
if [ -f "$ROOTFS_IMAGE" ]; then
    echo -e "\n========================================"
    echo "✅ 打包成功！"
    echo "镜像路径：$ROOTFS_IMAGE"
    echo "========================================"
else
    echo -e "\n❌ 打包失败！请查看 build.log 日志"
    exit 1
fi
