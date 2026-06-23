#!/bin/bash
# 03_DtsDev 专用同步脚本：递归同步全部 .c .h 文件
# 仅处理本目录下所有层级c/h源码，其他文件不纳入暂存区

# 切换到脚本所在目录（03_DtsDev）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}" || exit 1

echo "===== 开始同步 03_DtsDev 下所有 .c .h 文件 ====="

# 1. 只更新当前目录下已跟踪的c/h修改、重命名
git add -u -- . "*.c" "*.h"

# 2. 递归查找当前目录所有子目录 .c .h 加入暂存
find . -type f \( -name "*.c" -o -name "*.h" \) | xargs git add

echo "===== 仅显示03_DtsDev内待提交c/h文件 ====="
# 限定只看当前目录变更，不会输出其他目录
git status --porcelain . | grep -E "\.(c|h)$"

# 检测当前目录内是否存在源码变更
CH=$(git status --porcelain . | grep -E "\.(c|h)$")
if [ -z "${CH}" ];then
    echo "03_DtsDev 无 .c/.h 文件变更，无需提交推送"
    exit 0
fi

# 提交并推送远端
git commit -m "更新03_DtsDev设备树相关c/h源码 $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo "✅ 03_DtsDev c/h 文件同步推送完成"
