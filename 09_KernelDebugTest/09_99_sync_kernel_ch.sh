#!/bin/bash
# 09_KernelDebugTest 同步脚本：递归同步目录内全部 .c .h Makefile 文件
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}" || exit 1
echo "===== 开始同步 09_KernelDebugTest 下所有 .c .h Makefile 文件 ====="

# 递归查找 c/h/Makefile 并add
find . -type f \( -name "*.c" -o -name "*.h" -o -name "Makefile" \) | xargs git add

echo "===== 仅显示本目录待提交c/h/Makefile文件 ====="
git status --porcelain . | grep -E "\.(c|h)$|Makefile$"
CH=$(git status --porcelain . | grep -E "\.(c|h)$|Makefile$")

if [ -z "${CH}" ];then
    echo "09_KernelDebugTest 无 .c/.h/Makefile 文件变更，无需推送"
    exit 0
fi

git commit -m "更新09_KernelDebugTest内核调试相关c/h源码及Makefile $(date '+%Y-%m-%d %H:%M')"
git push origin main
echo "✅ 09_KernelDebugTest c/h/Makefile 文件同步完成"
