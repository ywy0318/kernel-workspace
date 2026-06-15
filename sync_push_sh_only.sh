#!/bin/bash
GIT_NAME="ywy0318"
GIT_MAIL="ywy0318@qq.com"
REMOTE_ADDR="git@github.com:ywy0318/kernel-workspace.git"
WORK_ROOT="$HOME/workspace"
MAX_FILE_MB=10

cd "${WORK_ROOT}" || exit 1

# 初始化仓库
if [ ! -d ".git" ];then
    git init
    git config user.name "${GIT_NAME}"
    git config user.email "${GIT_MAIL}"
    git branch -M main
fi

# 绑定远程
git remote remove origin 2>/dev/null
git remote add origin "${REMOTE_ADDR}"

# 清空历史暂存区，避免残留干扰
git rm --cached -r . 2>/dev/null

# 1. 保证所有一级目录（xx_XX）都被同步，空目录也保留
for top_dir in [0-9][0-9]_*; do
    git add --update --no-all "${top_dir}/." 2>/dev/null
done

# 2. 核心：只处理一级目录下的 .sh 文件，不进入子目录
for top_dir in [0-9][0-9]_*; do
    for file in "${top_dir}"*.sh; do
        if [ -f "$file" ]; then
            git add "$file"
        fi
    done
done

# 3. 同步脚本自身
git add "$0"

# 4. 过滤超过大小限制的文件
echo "===== 过滤大于 ${MAX_FILE_MB}MB 的文件 ====="
git ls-files | while read file_path
do
    file_kb=$(du -k "$file_path" | awk '{print $1}')
    file_mb=$(echo "$file_kb / 1024" | bc -l)
    if (( $(echo "$file_mb > $MAX_FILE_MB" | bc -l) )); then
        echo "剔除超限文件：$file_path  ${file_mb:.2f} MB"
        git reset HEAD -- "$file_path"
    fi
done

# 检查是否有可提交变更
CHG=$(git status --porcelain)
if [ -z "${CHG}" ];then
    echo "✅ 无新增/修改内容，无需推送"
    exit 0
fi

echo -e "\n===== 本次待推送文件列表 ====="
git status --porcelain

# 提交并推送
git commit -m "同步一级目录+首层脚本(不递归子目录) $(date '+%Y-%m-%d %H:%M:%S')"
git push -u origin main

echo -e "\n🎉 同步完成：一级目录完整保留，仅同步首层sh脚本"
