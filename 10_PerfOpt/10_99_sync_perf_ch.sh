#!/bin/bash
# 10_PerfOpt 同步脚本：递归同步目录内全部 .c .h 文件
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}" || exit 1

echo "===== 开始同步 10_PerfOpt 下所有 .c .h 文件 ====="

git add -u -- . "*.c" "*.h"
find . -type f \( -name "*.c" -o -name "*.h" \) | xargs git add

echo "===== 仅显示本目录待提交c/h文件 ====="
git status --porcelain . | grep -E "\.(c|h)$"

CH=$(git status --porcelain . | grep -E "\.(c|h)$")
if [ -z "${CH}" ];then
    echo "10_PerfOpt 无 .c/.h 文件变更，无需推送"
    exit 0
fi

git commit -m "更新10_PerfOpt性能优化相关c/h源码 $(date '+%Y-%m-%d %H:%M')"
git push origin main
echo "✅ 10_PerfOpt c/h 文件同步完成"
