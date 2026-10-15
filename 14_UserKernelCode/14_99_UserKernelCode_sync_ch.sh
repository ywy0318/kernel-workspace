#!/bin/bash
# 14_99_UserKernelCode_sync_ch.sh 专用同步脚本
# 同步范围：递归 14_UserKernelCode 所有层级
# .c .cpp .h .hpp Makefile makefile

# 切换到脚本所在目录（14_UserKernelCode）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}" || exit 1

echo "===== 开始同步 14_UserKernelCode 源码与构建文件 ====="
echo "同步范围：递归所有子目录 .c .cpp .h .hpp Makefile makefile"

# 1. 更新已跟踪文件的修改、重命名、删除
git add -u -- . "*.c" "*.cpp" "*.h" "*.hpp" "Makefile" "makefile"

# 2. 递归查找所有目标源码与Makefile加入暂存
find . -type f \( \
    -name "*.c" -o \
    -name "*.cpp" -o \
    -name "*.h" -o \
    -name "*.hpp" -o \
    -name "Makefile" -o \
    -name "makefile" \
\) | xargs git add

echo -e "\n===== 仅显示14_UserKernelCode内待提交目标文件 ====="
git status --porcelain . | grep -E "\.(c|cpp|h|hpp)$|Makefile|makefile"

# 检测当前目录内是否存在源码变更
CH=$(git status --porcelain . | grep -E "\.(c|cpp|h|hpp)$|Makefile|makefile")
if [ -z "${CH}" ];then
    echo "14_UserKernelCode 无目标文件变更，无需提交推送"
    exit 0
fi

# 提交并推送远端
git commit -m "更新14_UserKernelCode 用户态内核态代码：c/cpp/h/hpp/Makefile $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo -e "\n✅ 14_UserKernelCode 目标文件同步推送完成"
