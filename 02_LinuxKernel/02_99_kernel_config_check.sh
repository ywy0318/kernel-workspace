#!/bin/bash
# 02_99_kernel_config_check.sh
# 内核配置完整性校验脚本：必选驱动 + GICv2/GICv3互斥检查

set -e
CUR_DIR=$(pwd)

# 两套编译目录与对应源码配置文件路径
GCC_CONFIG="${CUR_DIR}/build-gcc/.config"
LLVM_CONFIG="${CUR_DIR}/build-llvm/.config"

echo "====================================="
echo "        内核配置校验工具"
echo "  1) 校验 GCC 内核 (build-gcc/.config)"
echo "  2) 校验 LLVM 内核 (build-llvm/.config)"
echo "====================================="
read -p "请输入序号 [1/2]：" CHOICE

# 选择对应配置文件
case "${CHOICE}" in
    1)
        TARGET_CFG="${GCC_CONFIG}"
        TARGET_NAME="GCC"
        ;;
    2)
        TARGET_CFG="${LLVM_CONFIG}"
        TARGET_NAME="LLVM"
        ;;
    *)
        echo "❌ 输入序号错误，脚本退出"
        exit 1
        ;;
esac

# 判断配置文件是否存在
if [ ! -f "${TARGET_CFG}" ]; then
    echo "❌ 错误：未找到 ${TARGET_NAME} 内核配置文件 ${TARGET_CFG}"
    echo "请先执行menuconfig生成配置后再校验！"
    exit 1
fi

# 全局错误计数
ERR_COUNT=0

# 通用校验函数：检测指定CONFIG_XXX必须等于y
check_must_y() {
    local cfg_key="$1"
    if grep -q "^${cfg_key}=y" "${TARGET_CFG}"; then
        echo "✅ ${cfg_key}=y"
    else
        echo "❌ ${cfg_key} 缺失或未设置为=y"
        ERR_COUNT=$((ERR_COUNT + 1))
    fi
}

echo -e "\n==================== 【第一部分：强制必选配置校验】 ===================="
MUST_LIST=(
    CONFIG_SERIAL_AMBA_PL011
    CONFIG_SERIAL_AMBA_PL011_CONSOLE
    CONFIG_VIRTIO_BLK
    CONFIG_PRINTK
    CONFIG_LOG_BUF_SHIFT
)
for item in "${MUST_LIST[@]}"; do
    check_must_y "${item}"
done

echo -e "\n==================== 【第二部分：GIC中断控制器互斥校验】 ===================="
# 读取GIC状态
GIC_V2_STATUS=$(grep -E "^CONFIG_ARM_GIC_V2=[yn]" "${TARGET_CFG}" || true)
GIC_V3_STATUS=$(grep -E "^CONFIG_ARM_GIC_V3=[yn]" "${TARGET_CFG}" || true)
GIC_MAIN=$(grep -q "^CONFIG_ARM_GIC=y" "${TARGET_CFG}"; echo $?)

# 先校验主开关CONFIG_ARM_GIC必须开启
if [ "${GIC_MAIN}" -eq 0 ]; then
    echo "✅ CONFIG_ARM_GIC=y"
else
    echo "❌ CONFIG_ARM_GIC 未开启，中断控制器不可用"
    ERR_COUNT=$((ERR_COUNT + 1))
fi

# 提取v2/v3的值
V2_VAL=$(echo "${GIC_V2_STATUS}" | cut -d'=' -f2)
V3_VAL=$(echo "${GIC_V3_STATUS}" | cut -d'=' -f2)
# 空值默认n
V2_VAL=${V2_VAL:-n}
V3_VAL=${V3_VAL:-n}

echo "CONFIG_ARM_GIC_V2=${V2_VAL}"
echo "CONFIG_ARM_GIC_V3=${V3_VAL}"

# 互斥逻辑：不能同时=y
if [ "${V2_VAL}" = "y" ] && [ "${V3_VAL}" = "y" ]; then
    echo "❌ 冲突错误：GICv2 和 GICv3 不能同时开启=y！只能二选一"
    ERR_COUNT=$((ERR_COUNT + 1))
elif [ "${V2_VAL}" = "n" ] && [ "${V3_VAL}" = "n" ]; then
    echo "❌ 缺失错误：GICv2 / GICv3 至少需要开启其中一个=y"
    ERR_COUNT=$((ERR_COUNT + 1))
else
    echo "✅ GIC版本配置符合互斥规则（仅单版本开启）"
fi

# 汇总输出
echo -e "\n==================== 【校验结果汇总】 ===================="
if [ "${ERR_COUNT}" -eq 0 ]; then
    echo "🎉 ${TARGET_NAME} 内核配置全部校验通过，无错误！可正常编译启动QEMU"
else
    echo "⚠️  检测到 ${ERR_COUNT} 项配置错误，请打开menuconfig修正后重新校验！"
    exit 1
fi