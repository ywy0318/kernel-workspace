#!/bin/bash
# 14_99_UserKernelCode_sync_ch.sh 专用同步脚本
# 同步范围：递归 14_UserKernelCode 目录下所有层级 .c .cpp 文件

# 切换到脚本所在目录（14_UserKernelCode）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}" || exit 1

echo "===== 开始同步 14_UserKernelCode 下所有 .c .cpp 文件 ====="

# 1. 更新已跟踪的 c/cpp 文件修改、重命名、删除
git add -u -- . "*.c" "*.cpp"

# 2. 递归查找当前目录所有子目录 .c .cpp 加入暂存
find . -type f \( -name "*.c" -o -name "*.cpp" \) | xargs git add

echo -e "\n===== 仅显示14_UserKernelCode内待提交c/cpp文件 ====="
git status --porcelain . | grep -E "\.(c|cpp)$"

# 检测当前目录内是否存在源码变更
CH=$(git status --porcelain . | grep -E "\.(c|cpp)$")
if [ -z "${CH}" ];then
    echo "14_UserKernelCode 无 .c/.cpp 文件变更，无需提交推送"
    exit 0
fi

# 提交并推送远端
git commit -m "更新14_UserKernelCode 用户态内核态代码 c/cpp源码 $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo -e "\n✅ 14_UserKernelCode c/cpp 文件同步推送完成"
