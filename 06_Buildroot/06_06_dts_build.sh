#!/bin/bash
set -e
set -u

OUTPUT_GCC="./output_gcc"
DUMP_DTB="${OUTPUT_GCC}/virt_dump.dtb"
DTS_SRC="${OUTPUT_GCC}/virt_base.dts"
MYVIRT_DTB="${OUTPUT_GCC}/myvirt.dtb"

echo "====================================================="
echo "06_06_dts_build.sh | dtb反编译 + dts编译生成自定义dtb"
echo "====================================================="

# 校验dump出来的dtb是否存在
if [ ! -f "${DUMP_DTB}" ]; then
    echo "ERROR: 找不到 ${DUMP_DTB}, 请先运行 06_05_qemu_dump_dtb.sh"
    exit 1
fi

# 1. dtb反编译成dts（只需要第一次执行）
echo "1. dtb -> dts 反编译: ${DUMP_DTB} ==> ${DTS_SRC}"
#dtc -I dtb -O dts "${DUMP_DTB}" -o "${DTS_SRC}"

echo "👉 请手动修改 ${DTS_SRC} 设备树源码，修改完成后再次运行本脚本编译dtb"
echo "2. dts -> dtb 编译: ${DTS_SRC} ==> ${MYVIRT_DTB}"
dtc -I dts -O dtb "${DTS_SRC}" -o "${MYVIRT_DTB}"

echo "✅ 编译完成！输出：${MYVIRT_DTB}"
ls -lh "${MYVIRT_DTB}"
