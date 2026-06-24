#!/bin/bash
# 04_10_sync_rootfs_src.sh 专用同步脚本：递归同步04_ManualRootFS目录内全部 .c .h 文件
# 过滤忽略目录：output_gcc output_llvm rootfs tmp_build_bash tmp_build_dropbear tmp_build_net tmp_net_svc
# 仅处理源码文件，忽略指定产物/临时目录，不纳入暂存区、不检测其变更

# 切换到脚本所在目录
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}" || exit 1

echo "===== 开始同步 04_ManualRootFS 下所有 .c .h 文件（过滤产物临时目录） ====="

# 1. 更新已跟踪的c/h修改、重命名，排除忽略目录
git add -u -- . "*.c" "*.h" \
    --exclude-dir=output_gcc \
    --exclude-dir=output_llvm \
    --exclude-dir=rootfs \
    --exclude-dir=tmp_build_bash \
    --exclude-dir=tmp_build_dropbear \
    --exclude-dir=tmp_build_net \
    --exclude-dir=tmp_net_svc

# 2. 递归查找所有 .c .h，跳过指定忽略目录，加入暂存
find . \
    -type f \( -name "*.c" -o -name "*.h" \) \
    -not -path "./output_gcc/*" \
    -not -path "./output_llvm/*" \
    -not -path "./rootfs/*" \
    -not -path "./tmp_build_bash/*" \
    -not -path "./tmp_build_dropbear/*" \
    -not -path "./tmp_build_net/*" \
    -not -path "./tmp_net_svc/*" \
| xargs git add

echo "===== 仅显示04_ManualRootFS内待提交c/h文件（已过滤产物目录） ====="
# 只展示源码变更，过滤忽略目录内文件
git status --porcelain . | grep -E "\.(c|h)$" | grep -vE "output_gcc|output_llvm|rootfs|tmp_build_bash|tmp_build_dropbear|tmp_build_net|tmp_net_svc"

# 检测有效源码变更（排除忽略目录内文件）
CH=$(git status --porcelain . | grep -E "\.(c|h)$" | grep -vE "output_gcc|output_llvm|rootfs|tmp_build_bash|tmp_build_dropbear|tmp_build_net|tmp_net_svc")
if [ -z "${CH}" ];then
    echo "04_ManualRootFS 无有效 .c/.h 源码变更（产物/临时目录已忽略），无需提交推送"
    exit 0
fi

# 提交并推送远端main分支
git commit -m "更新04_ManualRootFS根文件系统相关c/h源码 $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo "✅ 04_ManualRootFS 有效c/h 文件同步推送完成"