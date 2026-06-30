#!/bin/bash
# 05_02_prepare_rootfs_network_auth.sh
# 无需外部传参，默认使用 ./rootfs 作为根文件系统目录
# 自动配置rcS静态IP、telnetd/dropbear、root登录密码

# 内置固定rootfs路径
ROOTFS_DIR="./rootfs"

# 严格模式后置，避免未定义变量报错
set -e
set -u

# 网络配置参数
STATIC_IP="10.0.2.10"
NETMASK="255.255.255.0"
GATEWAY="10.0.2.2"
DNS="114.114.114.114"
# root密码密文 明文123456，$1转义为\$1防止被shell解析
ROOT_SHADOW="root:\$1\$mypwd\$Z8H5kGQx9nR8a7bC0dE6F.:0:0:99999:7:::"

# 校验rootfs目录是否存在
if [ ! -d "${ROOTFS_DIR}" ];then
    echo "❌ 错误：默认目录 ${ROOTFS_DIR} 不存在！请先编译安装busybox生成rootfs"
    exit 1
fi

ETC_INIT="${ROOTFS_DIR}/etc/init.d"
ETC="${ROOTFS_DIR}/etc"
mkdir -p "${ETC_INIT}"

# 生成开机rcS脚本
cat > "${ETC_INIT}/rcS" << EOF
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs tmpfs /tmp
mdev -s

# 配置静态网卡
ifconfig eth0 up
ifconfig eth0 ${STATIC_IP} netmask ${NETMASK}
route add default gw ${GATEWAY} eth0
echo "nameserver ${DNS}" > /etc/resolv.conf

# 启动远程登录服务
telnetd
dropbear
EOF
chmod +x "${ETC_INIT}/rcS"
echo "✅ [05_02] 已生成开机脚本 rcS，静态IP: ${STATIC_IP}"

# 生成用户密码文件
cat > "${ETC}/passwd" << EOF
root:x:0:0:root:/:/bin/sh
EOF

cat > "${ETC}/shadow" << EOF
${ROOT_SHADOW}
EOF

echo "✅ [05_02] root账号配置完成，默认密码：123456"
echo "=== rootfs网络与认证配置全部完成 ==="