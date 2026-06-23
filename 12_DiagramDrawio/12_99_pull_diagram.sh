#!/bin/bash
# 12_DiagramDrawio 专用拉取脚本：仅同步远端本目录绘图文件
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(dirname "${SCRIPT_DIR}")
cd "${ROOT_DIR}" || exit 1

echo "===== 拉取远端 12_DiagramDrawio 目录最新文件 ====="
# 先拉取远端最新提交
git fetch origin main

# 只检出远端main分支下12_DiagramDrawio目录，覆盖本地同目录文件
git checkout origin/main -- 12_DiagramDrawio

echo "===== 拉取完成，当前目录文件列表 ====="
ls -la "${SCRIPT_DIR}"
