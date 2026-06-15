#!/bin/bash
GIT_NAME="ywy0318"
GIT_MAIL="ywy0318@qq.com"
REMOTE_ADDR="git@github.com:ywy0318/kernel-workspace.git"
WORK_ROOT="$HOME/workspace"
MAX_FILE_MB=10

cd "${WORK_ROOT}" || exit 1

# 初始化仓库（仅首次运行）
if [ ! -d ".git" ];then
    git init
    git config user.name "${GIT_NAME}"
    git config user.email "${GIT_MAIL}"
    git branch -M main
    git remote add origin "${REMOTE_ADDR}"
fi

# 绑定远程仓库（避免地址失效）
git remote remove origin 2>/dev/null
git remote add origin "${REMOTE_ADDR}"

# --------------------------
# 1. 同步已跟踪文件的 mv/重命名/修改
# --------------------------
git add -u 2>/dev/null

# --------------------------
# 2. 保证所有一级目录（xx_XX）被Git识别（空目录也保留）
# --------------------------
for top_dir in [0-9][0-9]_*; do
    git add --update --no-all "${top_dir}/." 2>/dev/null
done

# --------------------------
# 3. 只添加/更新一级目录下直接的.sh脚本（关键修改：去掉了"只加新文件"的判断）
# --------------------------
for top_dir in [0-9][0-9]_*; do
    for file in "${top_dir}"*.sh; do
        if [ -f "$file" ]; then
            git add "$file"
        fi
    done
done

# --------------------------
# 4. 同步脚本自身和.gitignore
# --------------------------
git add "$0" .gitignore 2>/dev/null

# --------------------------
# 5. 过滤大于指定大小的文件（仅检查首层脚本，不碰子目录）
# --------------------------
echo "===== 过滤大于 ${MAX_FILE_MB}MB 的文件（仅首层脚本） ====="
for top_dir in [0-9][0-9]_*; do
    for file in "${top_dir}"*.sh; do
        if [ -f "$file" ] && git status --porcelain | grep -q "^[AM] ${file}"; then
            file_kb=$(du -k "$file" | awk '{print $1}')
            file_mb=$(echo "$file_kb / 1024" | bc -l)
            if (( $(echo "$file_mb > $MAX_FILE_MB" | bc -l) )); then
                echo "剔除超限文件：$file  ${file_mb:.2f} MB"
                git reset HEAD -- "$file"
            fi
        fi
    done
done

# --------------------------
# 6. 检查并提交变更
# --------------------------
CHG=$(git status --porcelain | grep -v "^D")
if [ -z "${CHG}" ];then
    echo "✅ 无新增/修改内容，无需推送"
    exit 0
fi

echo -e "\n===== 本次待推送文件列表 ====="
echo "${CHG}"

git commit -m "【增量更新】同步一级目录+首层脚本 $(date '+%Y-%m-%d %H:%M:%S')"
git push -u origin main

echo -e "\n🎉 同步完成：所有一级目录的首层脚本均已处理"
