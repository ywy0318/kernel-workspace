#!/bin/bash
GIT_NAME="ywy0318"
GIT_MAIL="ywy0318@qq.com"
REMOTE_ADDR="git@github.com:ywy0318/kernel-workspace.git"
WORK_ROOT="$HOME/workspace"
# 单文件上限：单位MB，超过该大小直接剔除，建议设10
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

# 清空旧暂存区，杜绝历史残留
git rm --cached -r . 2>/dev/null

# 第一步：批量收集所有一级目录首层sh脚本，加入暂存
ls -d [0-9][0-9]_*/ | while read top_dir
do
    find "${top_dir}" -maxdepth 1 -type f -name "*.sh" -print0 | xargs -0 git add
done
# 同步脚本自身加入暂存
git add "$0"

# 第二步：遍历暂存区所有文件，判断大小，超限则移出暂存区
echo "=== 开始检测单个文件大小，超过${MAX_FILE_MB}MB将剔除 ==="
git ls-files | while read file_path
do
    # 计算文件大小 MB
    file_size_KB=$(du -k "$file_path" | awk '{print $1}')
    file_size_MB=$(echo "$file_size_KB / 1024" | bc -l)

    # 大于阈值，移出暂存区
    if (( $(echo "$file_size_MB > $MAX_FILE_MB" | bc -l) )); then
        echo "超限剔除：$file_path 大小 ${file_size_MB:.2f}MB > ${MAX_FILE_MB}MB"
        git reset HEAD -- "$file_path"
    fi
done

# 检查最终剩余待提交变更
CHG=$(git status --porcelain)
if [ -z "${CHG}" ];then
    echo "✅ 无合法可上传脚本，无需推送"
    exit 0
fi

echo -e "\n===== 本次最终待上传合法文件列表 ====="
git status --porcelain

# 提交推送
git commit -m "auto upload filtered sh scripts, size limit ${MAX_FILE_MB}MB $(date '+%Y-%m-%d %H:%M:%S')"
git push -u origin main

echo -e "\n🎉 过滤完成，仅合规小尺寸sh脚本推送完毕"
