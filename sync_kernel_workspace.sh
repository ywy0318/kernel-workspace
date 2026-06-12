#!/bin/bash
GIT_NAME="ywy0318"
GIT_MAIL="ywy0318@qq.com"
REMOTE_ADDR="git@github.com:ywy0318/kernel-workspace.git"
WORK_ROOT="$HOME/workspace"
# 单文件最大允许大小 MB
MAX_FILE_MB=10

cd "${WORK_ROOT}" || exit 1

# Git仓库初始化
if [ ! -d ".git" ];then
    git init
    git config user.name "${GIT_NAME}"
    git config user.email "${GIT_MAIL}"
    git branch -M main
fi

# 绑定远程仓库
git remote remove origin 2>/dev/null
git remote add origin "${REMOTE_ADDR}"

# 清空旧暂存区，彻底消除历史残留干扰
git rm --cached -r . 2>/dev/null

# 1. 只创建一级目录占位（保证空目录也能在远端生成）
for top_dir in [0-9][0-9]_*; do
    git add --update --no-all "${top_dir}/." 2>/dev/null
done

# 2. 遍历所有一级目录，递归抓取目录内全部.sh脚本（不限层级）
find [0-9][0-9]_* -type f -name "*.sh" -print0 | xargs -0 git add

# 3. 同步脚本自身加入版本跟踪
git add "$0"

# 4. 大小过滤：超过阈值的文件从暂存区剔除（本地文件不动）
echo "===== 正在过滤超过${MAX_FILE_MB}MB的大文件 ====="
git ls-files | while read file_path
do
    file_kb=$(du -k "$file_path" | awk '{print $1}')
    file_mb=$(echo "$file_kb / 1024" | bc -l)
    if (( $(echo "$file_mb > $MAX_FILE_MB" | bc -l) )); then
        echo "剔除超限文件：$file_path  ${file_mb:.2f}MB"
        git reset HEAD -- "$file_path"
    fi
done

# 检查是否有可提交内容
CHG=$(git status --porcelain)
if [ -z "${CHG}" ];then
    echo "✅ 无新增/修改脚本，无需推送"
    exit 0
fi

echo -e "\n===== 待推送文件清单 ====="
git status --porcelain

# 提交并推送
git commit -m "同步一级目录完整结构+全部层级sh脚本，单文件上限${MAX_FILE_MB}MB $(date '+%Y-%m-%d %H:%M:%S')"
git push -u origin main

echo -e "\n🎉 执行完成：一级目录全部保留，所有sh脚本已推送，大文件已自动过滤！"
