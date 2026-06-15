#!/bin/bash
GIT_NAME="ywy0318"
GIT_MAIL="ywy0318@qq.com"
REMOTE_ADDR="git@github.com:ywy0318/kernel-workspace.git"
WORK_ROOT="$HOME/workspace"
MAX_FILE=10485760  # 10MB，单位是字节

cd "${WORK_ROOT}" || exit 1

# 1. 初始化仓库（仅首次运行）
if [ ! -d ".git" ];then
    git init
    git config user.name "${GIT_NAME}"
    git config user.email "${GIT_MAIL}"
    git branch -M main
    git remote add origin "${REMOTE_ADDR}"
fi

# 2. 绑定远程
git remote remove origin 2>/dev/null
git remote add origin "${REMOTE_ADDR}"

# 3. 同步 mv/重命名/修改
git add -u 2>/dev/null

# --------------------------
# 每个目录单独处理，只看首层脚本
# --------------------------

# 00_EnvScripts
git add --update --no-all 00_EnvScripts/. 2>/dev/null
for f in 00_EnvScripts/*.sh; do [ -f "$f" ] && git add "$f"; done

# 01_Uboot
git add --update --no-all 01_Uboot/. 2>/dev/null
for f in 01_Uboot/*.sh; do [ -f "$f" ] && git add "$f"; done

# 02_LinuxKernel
git add --update --no-all 02_LinuxKernel/. 2>/dev/null
for f in 02_LinuxKernel/*.sh; do [ -f "$f" ] && git add "$f"; done

# 03_DtsDev
git add --update --no-all 03_DtsDev/. 2>/dev/null
for f in 03_DtsDev/*.sh; do [ -f "$f" ] && git add "$f"; done

# 04_ManualRootFS
git add --update --no-all 04_ManualRootFS/. 2>/dev/null
for f in 04_ManualRootFS/*.sh; do [ -f "$f" ] && git add "$f"; done

# 05_BusyBox
git add --update --no-all 05_BusyBox/. 2>/dev/null
for f in 05_BusyBox/*.sh; do [ -f "$f" ] && git add "$f"; done

# 06_Buildroot
git add --update --no-all 06_Buildroot/. 2>/dev/null
for f in 06_Buildroot/*.sh; do [ -f "$f" ] && git add "$f"; done

# 07_Yocto
git add --update --no-all 07_Yocto/. 2>/dev/null
for f in 07_Yocto/*.sh; do [ -f "$f" ] && git add "$f"; done

# 08_QemuRun
git add --update --no-all 08_QemuRun/. 2>/dev/null
for f in 08_QemuRun/*.sh; do [ -f "$f" ] && git add "$f"; done

# 09_KernelDebugTest
git add --update --no-all 09_KernelDebugTest/. 2>/dev/null
for f in 09_KernelDebugTest/*.sh; do [ -f "$f" ] && git add "$f"; done

# 10_PerfOpt
git add --update --no-all 10_PerfOpt/. 2>/dev/null
for f in 10_PerfOpt/*.sh; do [ -f "$f" ] && git add "$f"; done

# 11_QemuDebootstrapRootFS
git add --update --no-all 11_QemuDebootstrapRootFS/. 2>/dev/null
for f in 11_QemuDebootstrapRootFS/*.sh; do [ -f "$f" ] && git add "$f"; done

# 同步脚本自身和.gitignore
git add "$0" .gitignore 2>/dev/null

# --------------------------
# 过滤大于10MB的文件
# --------------------------
echo "===== 过滤大于10MB的文件 ====="
for f in $(git status --porcelain | grep "^A" | awk '{print $2}'); do
    if [ -f "$f" ] && [ $(stat -c %s "$f") -gt $MAX_FILE ]; then
        echo "剔除超限文件：$f"
        git reset HEAD -- "$f"
    fi
done

# 检查变更
CHG=$(git status --porcelain | grep -v "^D")
if [ -z "$CHG" ]; then
    echo "✅ 无新增/修改内容，无需推送"
    exit 0
fi

echo -e "\n===== 本次待推送文件列表 ====="
echo "$CHG"

# 提交并推送
git commit -m "同步一级目录+首层脚本 $(date '+%Y-%m-%d %H:%M:%S')"
git push -u origin main

echo -e "\n🎉 同步完成"
