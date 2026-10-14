#!/bin/bash
set -e
set -u

OUTPUT_GCC="./output_gcc"
DUMP_DTB="${OUTPUT_GCC}/virt_dump.dtb"
DTS_OUT="${OUTPUT_GCC}/virt_base.dts"

echo "====================================================="
echo "06_05_01_dtb2dts.sh | dtb 反编译生成 dts"
echo "脚本启动时间: $(date "+%Y-%m-%d %H:%M:%S")"
echo "====================================================="

# 校验dtb文件是否存在
if [ ! -f "${DUMP_DTB}" ]; then
    echo "ERROR: ${DUMP_DTB} 不存在，请先运行 ./06_05_qemu_dump_dtb.sh"
    exit 1
fi

echo "开始反编译：${DUMP_DTB} ===> ${DTS_OUT}"
dtc -I dtb -O dts "${DUMP_DTB}" -o "${DTS_OUT}"

echo "✅ 反编译完成！"
ls -lh "${DTS_OUT}"
echo "👉 接下来可以编辑 virt_base.dts 修改设备树节点"
