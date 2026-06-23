#!/bin/bash
# 12_98_push_diagram.sh
# 仅同步当前12_DiagramDrawio目录下所有递归层级 *.drawio 文件至GitHub
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(dirname "${SCRIPT_DIR}")
cd "${SCRIPT_DIR}" || exit 1

echo "====================================="
echo "  仅同步 12_DiagramDrawio 下全部 .drawio 文件"
echo "====================================="

# 先拉取远端该目录最新内容，避免推送冲突
echo -e "\n===== 拉取远端 12_DiagramDrawio 最新文件 ====="
cd "${ROOT_DIR}"
git fetch origin main
git checkout origin/main -- 12_DiagramDrawio
cd "${SCRIPT_DIR}"

# 1. 更新已跟踪的drawio文件（修改/重命名）
git add -u -- . "*.drawio"

# 2. 递归查找所有子目录内 .drawio 文件加入暂存
find . -type f -name "*.drawio" | xargs git add

# 只展示当前目录下drawio相关变更，屏蔽其他目录输出
echo -e "\n===== 待提交 .drawio 文件列表 ====="
DIFF=$(git status --porcelain . | grep -E "\.drawio$")
echo "${DIFF}"

# 无drawio变更直接退出
if [ -z "${DIFF}" ];then
    echo -e "\n✅ 无 .drawio 文件变更，无需推送"
    exit 0
fi

# 提交
git commit -m "更新12_DiagramDrawio流程图drawio文件 $(date '+%Y-%m-%d %H:%M:%S')"

# 推送并判断执行结果
echo -e "\n===== 推送至GitHub远端 ====="
if git push origin main; then
    echo -e "\n🎉 所有drawio流程图同步推送完成"
else
    echo -e "\n❌ 推送失败！远端存在未同步更新，请检查网络或手动拉取后重试"
    exit 1
fi
