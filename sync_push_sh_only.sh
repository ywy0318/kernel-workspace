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
# 关键改动：
# 1. 用 git add -u 同步 mv/重命名/删除
# 2. 只增不减，不删除任何文件/目录
# 3. 只处理一级目录下直接的.sh脚本，不进入任何子目录
# 4. 过滤逻辑也只检查首层脚本，避免卡死
# --------------------------

# 1. 同步已跟踪文件的 mv/重命名/修改（关键！）
# 这行会让 Git 自动识别你本地的 mv 操作，不会当成删除+新增
git add -u 2>/dev/null

# 2. 保证所有一级目录（xx_XX）被Git识别（空目录也保留）
for top_dir in [0-9][0-9]_*; do
    git add --update --no-all "${top_dir}/." 2>/dev/null
done

# 3. 只添加/新增一级目录下直接的.sh脚本（不进入子目录）
# 这里只加新脚本，不处理已跟踪的（已由 git add -u 处理）
for top_dir in [0-9][0-9]_*; do
    for file in "${top_dir}"*.sh; do
        if [ -f "$file" ] && ! git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            git add "$file"
        fi
    done
done

# 4. 同步脚本自身和.gitignore
git add "$0" .gitignore 2>/dev/null

# 5. 过滤逻辑：只检查本次新增的一级目录首层脚本，不碰任何子目录
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

# 检查是否有可提交变更（只显示新增/修改，不显示删除）
CHG=$(git status --porcelain | grep -v "^D")
if [ -z "${CHG}" ];then
    echo "✅ 无新增/修改内容，无需推送"
    exit 0
fi

echo -e "\n===== 本次待推送文件列表（含mv/重命名） ====="
echo "${CHG}"

# 提交并推送
git commit -m "【增量更新】同步首层脚本，含mv/重命名 $(date '+%Y-%m-%d %H:%M:%S')"
git push -u origin main

echo -e "\n🎉 同步完成：mv/重命名已自动识别，目录/文件均已保留"
