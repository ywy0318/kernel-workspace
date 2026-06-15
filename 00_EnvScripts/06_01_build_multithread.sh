#!/bin/bash

BUILDROOT_DIR="buildroot-2023.02.9"

echo -e "\n===== 多核编译：工具链 + 所有软件包 =====\n"

cd "$BUILDROOT_DIR" || exit 1

unset LD_LIBRARY_PATH
unset MAKEFLAGS

# ========== 注意：make clean 已加上，但是注释状态 ==========
# 需要清理时，把前面的 # 删掉即可
# make clean

# 多核编译所有内容（不打包）
make -j$(nproc) world

echo -e "\n✅ 多核编译完成！请执行 06_02_package_singlethread.sh 进行打包\n"
