#!/bin/bash
set -e
set -u

# 配置常量，和04_01保持统一
IMG="rootfs.ext4"
IMG_SIZE=64
ROOTFS_DIR="${PWD}/rootfs"

NET_IP="10.0.2.15"
NET_MASK="255.255.255.0"
NET_GW="10.0.2.2"
DNS1="223.5.5.5"
DNS2="114.114.114.114"

# 前置校验rootfs存在
[ ! -d "${ROOTFS_DIR}" ] && echo "ERROR: 请先执行 04_01 + 04_02 生成完整rootfs" && exit 1

echo "============================================="
echo "生成系统配置文件与开机自启脚本"
echo "============================================="
# 主机名
echo "embed-linux" > "${ROOTFS_DIR}/etc/hostname"

# hosts
cat > "${ROOTFS_DIR}/etc/hosts" <<EOF
127.0.0.1       localhost
${NET_IP}       embed-linux
::1             localhost
EOF

# DNS
cat > "${ROOTFS_DIR}/etc/resolv.conf" <<EOF
nameserver ${DNS1}
nameserver ${DNS2}
EOF

# root免密登录
cat > "${ROOTFS_DIR}/etc/passwd" <<EOF
root::0:0:root:/:/bin/sh
EOF
touch "${ROOTFS_DIR}/etc/group" "${ROOTFS_DIR}/etc/shadow"

# 开机网络+SSH启动脚本（自动判断dropbear是否存在）
cat > "${ROOTFS_DIR}/etc/init.d/S01network" <<EOF
#!/bin/sh
net_tools ifconfig eth0 ${NET_IP} ${NET_MASK}
net_tools gw_add ${NET_GW}

if [ -x /bin/dropbear ];then
    if [ ! -f /etc/dropbear/dropbear_rsa_host_key ];then
        dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
    fi
    dropbear -r /etc/dropbear/dropbear_rsa_host_key
fi
EOF
chmod +x "${ROOTFS_DIR}/etc/init.d/S01network"

echo "系统配置写入完成，开始打包ext4镜像"
echo

# 构建镜像
dd if=/dev/zero of="${IMG}" bs=1M count="${IMG_SIZE}"
mkfs.ext4 -F "${IMG}"

sudo mount "${IMG}" /mnt
sudo cp -rf "${ROOTFS_DIR}"/* /mnt/
sudo umount /mnt

echo "============================================="
echo "✅ 镜像打包完成：${IMG}"
echo "============================================="
echo "QEMU启动命令参考："
echo 'qemu-system-aarch64 \
-M virt \
-cpu cortex-a53 \
-m 1G \
-nographic \
-kernel ./zImage \
-dtb ./virt.dtb \
-drive file='${IMG}',format=raw,if=virtio \
-net nic,model=virtio \
-net user,hostfwd=tcp::2222-:22 \
-append "root=/dev/vda rw console=ttyAMA0 init=/init"'
echo
echo "工具说明："
echo "net_tools ifconfig/gw_add/ping 基础网络工具"
echo "ssh/scp 仅在04_02下载编译成功后可用"
echo "============================================="
