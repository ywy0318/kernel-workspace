#!/bin/bash
# build_kernel_gcc.sh

# 保存当前目录（绝对路径）
CUR_DIR=$(pwd)

# 目录配置（已改为 gcc 专用源码目录）
KERNEL_DIR="$CUR_DIR/linux-6.1-gcc"
BUILD_DIR="$CUR_DIR/build-gcc"

# ====================== 新增：记录编译开始时间 ======================
START_TIME=$(date +%s)
echo -e "\n=================================================="
echo "编译开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo -e "==================================================\n"

# 1. 创建编译目录（如果不存在）
if [ ! -d "$BUILD_DIR" ]; then
    echo "创建编译目录: $BUILD_DIR"
    mkdir -p "$BUILD_DIR" || { echo "创建目录失败"; exit 1; }
else
    echo "编译目录已存在: $BUILD_DIR，跳过创建"
fi

# 2. 进入内核源码目录
cd "$KERNEL_DIR" || { echo "无法进入内核目录: $KERNEL_DIR"; exit 1; }

# 3. GCC 交叉编译配置
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

echo -e "\n==== 检查是否需要生成配置文件 ===="
# 只在没有 .config 时才执行 defconfig，避免每次重编
if [ ! -f "$BUILD_DIR/.config" ]; then
    echo "== 首次编译：生成默认配置 defconfig =="
    make O="$BUILD_DIR" defconfig
else
    echo "== 已有 .config，跳过 defconfig（增量编译模式） =="
fi

echo -e "\n==== 开始编译内核（GCC） ===="
make O="$BUILD_DIR" -j$(nproc)

# 4. 关键文件路径
IMAGE_SRC="$BUILD_DIR/arch/arm64/boot/Image"
DTB_SRC="$BUILD_DIR/arch/arm64/boot/dts/arm/virt.dtb"

echo -e "\n==== 拷贝输出文件到 build 目录 ===="
# 先检查 Image 是否生成成功
if [ ! -f "$IMAGE_SRC" ]; then
    echo "错误: 内核镜像 Image 不存在，编译失败"
    exit 1
fi

# 拷贝 Image 到 build 目录根
cp -f "$IMAGE_SRC" "$BUILD_DIR/" || { echo "错误: Image 拷贝失败"; exit 1; }
echo "✅ Image 拷贝成功: $BUILD_DIR/Image"

# 可选拷贝 virt.dtb（不存在也不影响）
if [ -f "$DTB_SRC" ]; then
    cp -f "$DTB_SRC" "$BUILD_DIR/"
    echo "✅ virt.dtb 拷贝成功: $BUILD_DIR/virt.dtb"
else
    echo "ℹ️ virt.dtb 不存在，跳过拷贝（不影响使用）"
fi

echo -e "\n==== 计算输出文件 MD5 ===="
cd "$BUILD_DIR" || exit
if [ -f "Image" ]; then
    echo "Image:"
    md5sum Image
else
    echo "错误: Image 不存在，拷贝失败"
    exit 1
fi
if [ -f "virt.dtb" ]; then
    echo "virt.dtb:"
    md5sum virt.dtb
fi

# 回到最初目录
cd "$CUR_DIR" || exit

# ====================== 新增：计算并显示总耗时 ======================
END_TIME=$(date +%s)
ELAPSED_SEC=$((END_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED_SEC / 60))
ELAPSED_REMAIN_SEC=$((ELAPSED_SEC % 60))

echo -e "\n=================================================="
echo "编译结束时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "总编译耗时：${ELAPSED_MIN}分${ELAPSED_REMAIN_SEC}秒 (${ELAPSED_SEC}秒)"
echo -e "==================================================\n"

echo -e "\n✅ GCC 编译完成，已回到当前目录: $(pwd)"
echo "产物路径: $BUILD_DIR"
echo "目录文件列表:"
ls -l "$BUILD_DIR"
