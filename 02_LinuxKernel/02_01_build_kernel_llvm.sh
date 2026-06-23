#!/bin/bash
# 02_01_build_kernel_llvm.sh

# 保存当前目录（绝对路径）
CUR_DIR=$(pwd)

# 目录配置（llvm 专用源码目录）
KERNEL_DIR="$CUR_DIR/linux-6.18-llvm"
BUILD_DIR="$CUR_DIR/build-llvm"

# ====================== 记录编译开始时间 ======================
START_TIME=$(date +%s)
echo -e "\n=================================================="
echo "编译开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo -e "==================================================\n"

# 1. 仅首次创建目录，不清空已有目录内容（保留配置）
if [ ! -d "$BUILD_DIR" ]; then
    echo "首次编译：创建编译目录 $BUILD_DIR"
    mkdir -p "$BUILD_DIR" || { echo "创建目录失败"; exit 1; }
else
    echo "编译目录已存在，保留已有配置，不清空"
fi

# 2. 进入内核源码目录
cd "$KERNEL_DIR" || { echo "无法进入内核目录: $KERNEL_DIR"; exit 1; }

# 3. LLVM 交叉编译配置
export ARCH=arm64
export LLVM=1  # 自动使用 clang/llvm 工具链
export CC=clang
export LD=ld.lld

echo -e "\n==== 检查是否需要生成配置文件 ===="
# 只在没有 .config 时才执行 defconfig，避免覆盖自定义配置
if [ ! -f "$BUILD_DIR/.config" ]; then
    echo "== 首次编译：生成默认配置 defconfig =="
    make O="$BUILD_DIR" defconfig
else
    echo "== 已有 .config，跳过 defconfig（使用自定义配置编译） =="
    echo "== 如需修改配置，请执行：make O=$BUILD_DIR menuconfig =="
fi

echo -e "\n==== 开始编译内核（LLVM） ===="
make O="$BUILD_DIR" -j$(nproc)

# 4. 关键文件路径
IMAGE_SRC="$BUILD_DIR/arch/arm64/boot/Image"
DTB_SRC="$BUILD_DIR/arch/arm64/boot/dts/arm/virt.dtb"

echo -e "\n==== 拷贝输出文件到 build 目录 ===="
# 检查内核镜像
if [ ! -f "$IMAGE_SRC" ]; then
    echo "错误: 内核镜像 Image 不存在，编译失败"
    exit 1
fi

cp -f "$IMAGE_SRC" "$BUILD_DIR/" || { echo "错误: Image 拷贝失败"; exit 1; }
echo "✅ Image 拷贝成功: $BUILD_DIR/Image"

# 拷贝设备树
if [ -f "$DTB_SRC" ]; then
    cp -f "$DTB_SRC" "$BUILD_DIR/"
    echo "✅ virt.dtb 拷贝成功: $BUILD_DIR/virt.dtb"
else
    echo "ℹ️ virt.dtb 不存在，跳过拷贝（不影响使用）"
fi

# 5. 仅终端打印 MD5、SHA256，不生成文件
echo -e "\n==== 文件校验结果 ===="
cd "$BUILD_DIR" || exit
echo "【MD5SUM】"
md5sum Image virt.dtb 2>/dev/null

echo -e "\n【SHA256SUM】"
sha256sum Image virt.dtb 2>/dev/null

# 回到最初目录
cd "$CUR_DIR" || exit
# 查看编译器版本（最准确）
#readelf -p .comment ./vmlinux
#strings ./vmlinux | grep -i "gcc\|clang\|llvm" | head -5
# ====================== 计算总耗时 ======================
END_TIME=$(date +%s)
ELAPSED_SEC=$((END_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED_SEC / 60))
ELAPSED_REMAIN_SEC=$((ELAPSED_SEC % 60))

echo -e "\n=================================================="
echo "编译结束时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "总编译耗时：${ELAPSED_MIN}分${ELAPSED_REMAIN_SEC}秒 (${ELAPSED_SEC}秒)"
echo -e "==================================================\n"

echo -e "\n✅ LLVM 编译完成，已回到当前目录: $(pwd)"
echo "产物路径: $BUILD_DIR"
echo "目录文件列表:"
ls -l "$BUILD_DIR"
