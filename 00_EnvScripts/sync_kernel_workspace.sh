#!/bin/bash
set -euo pipefail

########################## 已按你的信息配置完毕 ##########################
GIT_USER_NAME="ywy0318"
GIT_USER_EMAIL="825579631@qq.com"
REMOTE_GIT_URL="git@github.com:ywy0318/kernel-workspace.git"
SYNC_ROOT="$HOME/workspace"
##########################################################################

echo "========================================"
echo "        Linux内核开发脚本一键同步工具"
echo "同步目录：$SYNC_ROOT"
echo "远程仓库：$REMOTE_GIT_URL"
echo "========================================"

# 进入工作目录
cd "${SYNC_ROOT}" || { echo "ERROR：无法进入 ${SYNC_ROOT}"; exit 1; }

# 首次初始化本地Git仓库
if [ ! -d ".git" ]; then
    echo "本地未初始化Git，正在执行 git init ..."
    git init
    git config user.name "${GIT_USER_NAME}"
    git config user.email "${GIT_USER_EMAIL}"
    echo "本地Git初始化完成"
else
    echo "检测到已有本地Git仓库，跳过初始化"
fi

# 绑定远程仓库
git remote remove origin 2>/dev/null
git remote add origin "${REMOTE_GIT_URL}"
echo "远程仓库绑定成功"

# 只递归添加所有子目录里的 *.sh 脚本，完整保留目录结构
echo "正在检索所有层级Shell脚本..."
find . -type f -name "*.sh" > /tmp/sh_file_list.tmp
xargs git add < /tmp/sh_file_list.tmp
rm -f /tmp/sh_file_list.tmp

# 判断有无变更
CHANGES=$(git status --porcelain)
if [ -z "$CHANGES" ]; then
    echo "✅ 没有脚本发生改动，无需同步推送"
    exit 0
fi

echo -e "\n本次改动文件列表："
git status --porcelain

# 自动提交，附带时间戳
COMMIT_MSG="auto update shell scripts: $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "${COMMIT_MSG}"

# 推送到远程main分支
echo -e "\n正在推送至GitHub远程仓库..."
git push -u origin main

echo -e "\n🎉 全部Shell脚本同步完成，目录结构完整上传！"
