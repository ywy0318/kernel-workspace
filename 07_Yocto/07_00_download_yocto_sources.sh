#!/bin/bash
set -e

# ---------- 1. 安装依赖 ----------
echo "============================================="
echo "正在安装 Yocto 依赖包..."
echo "============================================="
sudo apt update
sudo apt install -y chrpath diffstat gawk lz4 build-essential libncurses5-dev libssl-dev
echo "依赖安装完成！"
echo

# ---------- 2. 工作目录配置 ----------
WORK_DIR=~/workspace/07_Yocto
SOURCE_DIR=$WORK_DIR/yocto-sources
mkdir -p $SOURCE_DIR
cd $SOURCE_DIR

# ---------- 3. 定义函数：不存在则克隆，存在则拉最新 ----------
clone_or_pull() {
    local name="$1"
    local url="$2"
    local branch="$3"

    if [ -d "$name" ]; then
        echo "============================================="
        echo "🔄 $name 已存在，拉取 $branch 最新代码..."
        echo "============================================="
        cd "$name"
        git checkout "$branch"
        git pull origin "$branch"
        cd ..
    else
        echo "============================================="
        echo "⬇️ 正在克隆 $name ($branch)..."
        echo "============================================="
        git clone -b "$branch" "$url" "$name"
    fi
}

# ====================== 仅修改此处分支参数 ======================
# 切换为 mickledore 分支，原生支持linux 6.1内核
TARGET_BRANCH="mickledore"
clone_or_pull "poky" "https://git.yoctoproject.org/git/poky" "${TARGET_BRANCH}"
clone_or_pull "meta-openembedded" "https://git.openembedded.org/meta-openembedded" "${TARGET_BRANCH}"

echo
echo "✅ 所有源码同步完成！目标分支：${TARGET_BRANCH}，路径：$SOURCE_DIR"
echo "接下来执行编译脚本即可编译6.1内核镜像"
