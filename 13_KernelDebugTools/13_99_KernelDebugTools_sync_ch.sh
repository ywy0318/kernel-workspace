#!/bin/bash
# 13_99_KernelDebugTools_sync_ch.sh 专用同步脚本
# 同步范围：
# 1. 递归所有层级 .c .h
# 2. 仅根目录 tool_dir_explain.txt
# 3. 所有子目录下的 *.sh（当前13_KernelDebugTools根目录下的sh不纳入）

# 切换到脚本所在目录（13_KernelDebugTools）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}" || exit 1

echo "===== 开始同步 13_KernelDebugTools 目标文件 ====="
echo "同步范围：所有层级.c/.h、根目录tool_dir_explain.txt、各级子目录下.sh（根目录sh忽略）"

# 1. 更新已跟踪文件的修改/删除/重命名
git add -u -- . "*.c" "*.h" "tool_dir_explain.txt"

# 2. 递归添加所有 .c .h
find . -type f \( -name "*.c" -o -name "*.h" \) | xargs git add

# 3. 添加根目录 tool_dir_explain.txt（处理新增文件）
[ -f "./tool_dir_explain.txt" ] && git add ./tool_dir_explain.txt

# 4. 仅递归子目录中的 .sh 文件（排除当前根目录下的sh）
# 查找深度至少1层，只匹配子文件夹内sh，根目录sh不会被选中
find . -mindepth 2 -type f -name "*.sh" | xargs git add

echo -e "\n===== 仅展示待提交的目标文件 ====="
git status --porcelain . | grep -E "\.(c|h|sh)$|tool_dir_explain.txt"

# 检测是否存在目标文件变更
CH=$(git status --porcelain . | grep -E "\.(c|h|sh)$|tool_dir_explain.txt")
if [ -z "${CH}" ];then
    echo "13_KernelDebugTools 无待提交文件变更，无需提交推送"
    exit 0
fi

# 提交并推送
git commit -m "更新13_KernelDebugTools：内核调试工具c/h源码、子目录脚本、说明文档 $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo -e "\n✅ 13_KernelDebugTools 全部目标文件同步推送完成"