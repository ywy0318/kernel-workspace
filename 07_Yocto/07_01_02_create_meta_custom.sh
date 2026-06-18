#!/bin/bash
set -e

# 项目根目录固定
WORK_ROOT=~/workspace/07_Yocto
META_CUSTOM=${WORK_ROOT}/meta-custom
BUILD_CONF=${WORK_ROOT}/build_uboot_kernel_rootfs/conf/bblayers.conf

echo "============================================="
echo "开始创建自定义层 meta-custom，路径：${META_CUSTOM}"
echo "============================================="

# 1. 创建完整目录层级
mkdir -p \
    ${META_CUSTOM}/conf \
    ${META_CUSTOM}/recipes-core/systemd/systemd-networkd

# 2. 生成 layer.conf（Yocto层识别必需文件）
cat > ${META_CUSTOM}/conf/layer.conf <<'EOF'
BBPATH .= "${LAYERDIR}:"
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb ${LAYERDIR}/recipes-*/*/*.bbappend"
BBFILE_COLLECTIONS += "custom"
BBFILE_PATTERN_custom = "^${LAYERDIR}/"
BBFILE_PRIORITY_custom = "6"
EOF
echo "✅ 生成层配置文件：meta-custom/conf/layer.conf"

# 3. 写入静态IP网卡配置文件 20-eth0-static.network
cat > ${META_CUSTOM}/recipes-core/systemd/systemd-networkd/20-eth0-static.network <<'EOF'
[Match]
Name=eth0
[Network]
Address=10.0.2.10/24
Gateway=10.0.2.2
DNS=114.114.114.114
DNS=8.8.8.8
EOF
echo "✅ 写入静态IP网卡配置文件"

# 4. 生成 systemd-networkd.bbappend 部署脚本
cat > ${META_CUSTOM}/recipes-core/systemd/systemd-networkd.bbappend <<'EOF'
SRC_URI += "file://20-eth0-static.network"

do_install:append() {
    install -d ${D}${systemd_unitdir}/network/
    install -m 644 ${WORKDIR}/20-eth0-static.network ${D}${systemd_unitdir}/network/
}

SYSTEMD_SERVICE:${PN} += "systemd-networkd.service systemd-resolved.service"
EOF
echo "✅ 生成网卡配置部署bbappend文件"

# 5. 自动检查并把meta-custom写入bblayers.conf，避免重复添加
CUSTOM_LAYER_LINE="/home/ubuntu/workspace/07_Yocto/meta-custom \\"
if grep -q "${CUSTOM_LAYER_LINE}" ${BUILD_CONF}; then
    echo "ℹ️  bblayers.conf 已包含meta-custom，无需重复添加"
else
    sed -i "/BBLAYERS \?= \".*\\\\$/a \  ${CUSTOM_LAYER_LINE}" ${BUILD_CONF}
    echo "✅ 已将meta-custom层追加到 bblayers.conf"
fi

echo -e "\n============================================="
echo "🎉 meta-custom 自定义层全部创建完成！"
echo "层目录：${META_CUSTOM}"
echo "静态IP：10.0.2.10/24（适配QEMU slirp）"
echo "============================================="
# 执行完毕自动退回项目根目录
cd ${WORK_ROOT}
echo "当前目录：$(pwd)"
