#!/bin/bash
# 06_00_01_create_custom_skeleton.sh
# 功能：生成固化静态IP的custom_skeleton骨架文件，编译前手动执行
set -e

# ========== 路径配置（与你现有工作目录统一） ==========
WORK_BASE="/home/ubuntu/workspace/06_Buildroot"
BR_DIR_NAME="buildroot-2025.02"
BR_ROOT="${WORK_BASE}/${BR_DIR_NAME}"
SKELETON_PATH="${BR_ROOT}/custom_skeleton"

echo "============================================="
echo "自定义静态IP骨架生成脚本"
echo "Buildroot源码路径：${BR_ROOT}"
echo "骨架输出目录：${SKELETON_PATH}"
echo "============================================="

# 校验buildroot源码是否存在
if [ ! -d "${BR_ROOT}" ]; then
    echo "❌ 错误：未找到 ${BR_DIR_NAME} 源码目录，请先执行 06_00_download_buildroot_202502.sh 下载解压"
    exit 1
fi

# 创建完整目录层级
echo "📂 创建骨架目录层级"
mkdir -p "${SKELETON_PATH}/etc/network"
mkdir -p "${SKELETON_PATH}/etc/init.d"

# 写入静态IP配置文件 interfaces
echo "📝 写入静态IP配置 /etc/network/interfaces"
cat > "${SKELETON_PATH}/etc/network/interfaces" << EOF
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8
EOF

# 写入网络开机自启脚本 S40network
echo "📝 写入网卡开机自启脚本 /etc/init.d/S40network"
cat > "${SKELETON_PATH}/etc/init.d/S40network" << EOF
#!/bin/sh
case "\$1" in
start)
    echo "[NET] 启动静态网卡eth0"
    /sbin/ifup eth0
    ;;
stop)
    echo "[NET] 关闭网卡eth0"
    /sbin/ifdown eth0
    ;;
restart)
    echo "[NET] 重启网卡eth0"
    /sbin/ifdown eth0
    /sbin/ifup eth0
    ;;
esac
EOF

# 赋予启动脚本可执行权限
chmod +x "${SKELETON_PATH}/etc/init.d/S40network"

echo -e "\n✅ 骨架文件全部生成完成！"
echo "📌 后续操作提示："
echo "1. 进入 ${BR_ROOT} 执行 make menuconfig"
echo "2. System configuration → Custom skeleton directory 填写 \$(TOPDIR)/custom_skeleton"
echo "3. 保存配置后再执行编译脚本 06_01_build_multithread.sh"
echo "============================================="
exit 0
