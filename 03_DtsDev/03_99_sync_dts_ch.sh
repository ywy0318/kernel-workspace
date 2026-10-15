#!/bin/bash
# 03_DtsDev 专用同步脚本：递归同步全部 .c .h .dts 文件（含dtsi）
# 仅处理本目录下所有层级 c/h/dts/dtsi 源码，其他文件不纳入暂存区
# 脚本名称：03_99_sync_dts_ch.sh

# 切换到脚本所在目录（03_DtsDev）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}" || { echo "❌ 切换目录失败：${SCRIPT_DIR}"; exit 1; }
echo "===== 开始同步 03_DtsDev 下所有 .c .h .dts .dtsi 文件 ====="

# 1. 更新【已经被git跟踪】的 c/h/dts/dtsi 修改、删除、重命名文件
git add -u -- .

# 2. 递归查找当前目录所有子目录 .c .h .dts .dtsi，加入暂存区（新增文件）
find . -type f \( -name "*.c" -o -name "*.h" -o -name "*.dts" -o -name "*.dtsi" \) | xargs git add

echo "===== 仅显示03_DtsDev内待提交 c/h/dts/dtsi 文件 ====="
# 限定只看当前目录变更，过滤目标后缀
git status --porcelain . | grep -E "\.(c|h|dts|dtsi)$"

# 检测当前目录内是否存在源码/设备树变更
CH=$(git status --porcelain . | grep -E "\.(c|h|dts|dtsi)$")
if [ -z "${CH}" ];then
    echo "03_DtsDev 无 .c/.h/.dts/.dtsi 文件变更，无需提交推送"
    exit 0
fi

# 提交并推送远端
git commit -m "更新03_DtsDev设备树相关 c/h/dts/dtsi 源码 $(date '+%Y-%m-%d %H:%M')" || {
    echo "❌ git commit 执行失败"
    exit 1
}
git push origin main || {
    echo "❌ git push origin main 执行失败"
    exit 1
}

echo "✅ 03_DtsDev c/h/dts/dtsi 文件同步推送完成"
