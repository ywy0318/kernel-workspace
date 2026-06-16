#!/bin/bash
# 05_03_prepare_rootfs_network_auth.sh
# 自动配置rcS固定静态IP、开机自启telnetd/dropbear、预置root登录密码
set -e
set -u

# 外部传入 rootfs 目录路径
ROOTFS_DIR="$1"
# QEMU virt 网络固定参数，可按需修改
STATIC_IP="10.0.2.10"
NETMASK="255.255.255.0"
GATEWAY="10.0.2.2"
DNS="114.114.114.114"
# root密码密文，明文密码：123456，更换密码用 openssl passwd -1 重新生成替换
#ROOT_SHADOW="root:$1$mypwd$Z8H5kGQx9nR8a7bC0dE6F.:0:0:99999:7:::"
# root密码密文，明文密码：123456，更换密码用 openssl passwd -1 重新生成替换
ROOT_SHADOW='root:$1$mypwd$Z8H5kGQx9nR8a7bC0dE6F.:0:0:99999:7:::'
# 参数校验
if [ $# -ne 1 ];then
    echo "使用方式：$0 ./rootfs"
    exit 1
fi
if [ ! -d "${ROOTFS_DIR}" ];then
    echo "❌ 错误：目录 ${ROOTFS_DIR} 不存在，请先完成BusyBox安装"
    exit 1
fi

ETC_INIT="${ROOTFS_DIR}/etc/init.d"
ETC="${ROOTFS_DIR}/etc"
mkdir -p "${ETC_INIT}"

# 1. 生成开机自启脚本 rcS（固定IP + 启动telnetd/dropbear）
cat > "${ETC_INIT}/rcS" << EOF
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs tmpfs /tmp
mdev -s

# 静态固定网卡IP
ifconfig eth0 up
ifconfig eth0 ${STATIC_IP} netmask ${NETMASK}
route add default gw ${GATEWAY} eth0
echo "nameserver ${DNS}" > /etc/resolv.conf

# 开启远程登录服务
telnetd
#dropbear
EOF
chmod +x "${ETC_INIT}/rcS"
echo "✅ [05_03] 已生成开机脚本 rcS，静态IP: ${STATIC_IP}"

# 2. 生成账号密码文件 passwd + shadow
cat > "${ETC}/passwd" << EOF
root:x:0:0:root:/:/bin/sh
EOF
cat > "${ETC}/shadow" << EOF
${ROOT_SHADOW}
EOF
echo "✅ [05_03] 已预置root账号，默认密码：123456"
echo "--- [05_03] rootfs网络与权限配置完成 ---"
