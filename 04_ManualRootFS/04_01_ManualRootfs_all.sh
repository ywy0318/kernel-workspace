#!/bin/bash
# 04_01_ManualRootfs_all.sh
# 一键完整构建手工根文件系统：
# 建目录 → 编译静态init → 创设备节点 → 编译静态bash
# → 静态编译网络工具+SSH+Telnet+scp → 配置固定IP/账号/自启
# → 打包生成 ext4 镜像
set -e
set -u

# ===================== 可配置项 =====================
BASH_VERSION="5.2.32"
IMG="rootfs.ext4"
IMG_SIZE=64
ROOTFS_DIR="${PWD}/rootfs"
TMP_BUILD_BASH="./tmp_build_bash"
TMP_BUILD_NET="./tmp_net_svc"

# 网络固定IP配置(QEMU默认网段)
NET_IP="10.0.2.15"
NET_MASK="255.255.255.0"
NET_GW="10.0.2.2"
DNS1="223.5.5.5"
DNS2="114.114.114.114"
# ====================================================

# 全局检查交叉工具链
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "❌ 请先安装工具链：sudo apt install gcc-aarch64-linux-gnu"
    exit 1
fi
CROSS=aarch64-linux-gnu-

####################################################
# 步骤1：创建rootfs基础目录
####################################################
echo "[1/7] 创建rootfs目录结构..."
mkdir -p "${ROOTFS_DIR}"/{bin,dev,etc,lib,proc,sys,tmp,var,run,sbin,usr/bin,usr/sbin,etc/init.d,etc/dropbear}
chmod 1777 "${ROOTFS_DIR}/tmp"
echo "[1/7] 完成"
echo

####################################################
# 步骤2：交叉编译静态 init
####################################################
echo "[2/7] 交叉编译静态 /init..."
aarch64-linux-gnu-gcc -static -o "${ROOTFS_DIR}/init" init.c
chmod +x "${ROOTFS_DIR}/init"
echo "[2/7] 完成"
echo

####################################################
# 步骤3：创建 /dev 必要设备节点
####################################################
echo "[3/7] 创建设备节点（需要sudo）..."
sudo mknod "${ROOTFS_DIR}/dev/console" c 5 1
sudo mknod "${ROOTFS_DIR}/dev/null"  c 1 3
echo "[3/7] 完成"
echo

####################################################
# 步骤4：交叉编译 真静态 bash
####################################################
echo "[4/7] 开始交叉编译 bash-${BASH_VERSION} (aarch64 真静态)..."
rm -rf "${TMP_BUILD_BASH}"
mkdir -p "${TMP_BUILD_BASH}"
cd "${TMP_BUILD_BASH}"

SRC_TAR="bash-${BASH_VERSION}.tar.gz"
if [ -f "${SRC_TAR}" ]; then
    echo "✅ 源码包已存在，跳过下载：${SRC_TAR}"
else
    echo "下载 bash 源码..."
    wget "https://ftp.gnu.org/gnu/bash/${SRC_TAR}"
fi

tar -xf "${SRC_TAR}"
cd "bash-${BASH_VERSION}"

./configure \
    CC=aarch64-linux-gnu-gcc \
    --host=aarch64-linux-gnu \
    --enable-static \
    --enable-static-link \
    --disable-shared \
    --disable-pie \
    --without-bash-malloc \
    --prefix="$(pwd)/install"

make -j$(nproc)
make install

cp install/bin/bash "${ROOTFS_DIR}/bin/"
chmod +x "${ROOTFS_DIR}/bin/bash"
ln -sf bash "${ROOTFS_DIR}/bin/sh"

cd ../..

echo "[4/7] ✅ bash 编译完成！"
echo "--- 验证 bash 静态链接 ---"
file "${ROOTFS_DIR}/bin/bash"
aarch64-linux-gnu-readelf -l "${ROOTFS_DIR}/bin/bash" | grep interpreter
echo

####################################################
# 步骤5：静态编译网络工具 & 服务
# net-tools(ifconfig/route) + dropbear(SSH/scp) + inetd+telnetd
####################################################
echo "[5/7] 开始静态编译网络工具与服务..."
rm -rf "${TMP_BUILD_NET}"
mkdir -p "${TMP_BUILD_NET}"
cd "${TMP_BUILD_NET}"

# 5.1 编译 net-tools
echo "---- 编译 net-tools ----"
wget -q https://sourceforge.net/projects/net-tools/files/net-tools-2.10.tar.xz
tar -xf net-tools-2.10.tar.xz
cd net-tools-2.10
make CC=${CROSS}gcc AR=${CROSS}ar RANLIB=${CROSS}ranlib CFLAGS="-static"
cp ifconfig route ../../${ROOTFS_DIR}/bin/
cd ..

# 5.2 编译 dropbear SSH + 内置 dbscp（支持 scp 传输）
echo "---- 编译 Dropbear SSH & dbscp ----"
wget -q https://mjt.dr.lqnr.com/dropbear/dropbear-2024.86.tar.bz2
tar -jxf dropbear-2024.86.tar.bz2
cd dropbear-2024.86
./configure --host=aarch64-linux-gnu --enable-static --disable-zlib
make -j$(nproc)

# 拷贝 ssh 服务端程序
cp dropbear dropbearkey ../../${ROOTFS_DIR}/sbin/
# 拷贝 dbscp 并创建 scp 软链接，兼容标准 scp 命令
cp dbscp ../../${ROOTFS_DIR}/usr/bin/
ln -sf dbscp ../../${ROOTFS_DIR}/usr/bin/scp

cd ..

# 5.3 编译 inetd + telnetd
echo "---- 编译 inetd & telnetd ----"
wget -q https://ftp.gnu.org/gnu/inetutils/inetutils-2.4.tar.xz
tar -xf inetutils-2.4.tar.xz
cd inetutils-2.4
./configure \
--host=aarch64-linux-gnu \
--enable-static \
--disable-hostname \
--disable-logger \
--disable-ping
make -j$(nproc)
cp src/inetd src/telnetd ../../${ROOTFS_DIR}/usr/sbin/
cd ..

cd ..
rm -rf "${TMP_BUILD_NET}"
echo "[5/7] ✅ 网络工具、SSH、Telnet、scp 编译完成"
echo

####################################################
# 步骤6：手动配置系统、固定IP、服务自启、账号
####################################################
echo "[6/7] 配置网络、账号、开机自启服务..."
# 6.1 主机名
echo "embed-linux" > "${ROOTFS_DIR}/etc/hostname"

# 6.2 hosts
cat > "${ROOTFS_DIR}/etc/hosts" <<EOF
127.0.0.1   localhost embed-linux
::1         localhost
${NET_IP} embed-linux
EOF

# 6.3 DNS
cat > "${ROOTFS_DIR}/etc/resolv.conf" <<EOF
nameserver ${DNS1}
nameserver ${DNS2}
EOF

# 6.4 账号配置 root 免密登录
cat > "${ROOTFS_DIR}/etc/passwd" <<EOF
root::0:0:root:/:/bin/sh
EOF
touch "${ROOTFS_DIR}/etc/group" "${ROOTFS_DIR}/etc/shadow"

# 6.5 固定IP 开机脚本 S01network
cat > "${ROOTFS_DIR}/etc/init.d/S01network" <<'EOF'
#!/bin/sh
echo "Configure static IP for eth0..."
ifconfig eth0 @IP@ netmask @MASK@ up
route add default gw @GW@ eth0
EOF
# 替换IP参数
sed -i "s|@IP@|${NET_IP}|g" "${ROOTFS_DIR}/etc/init.d/S01network"
sed -i "s|@MASK@|${NET_MASK}|g" "${ROOTFS_DIR}/etc/init.d/S01network"
sed -i "s|@GW@|${NET_GW}|g" "${ROOTFS_DIR}/etc/init.d/S01network"
chmod +x "${ROOTFS_DIR}/etc/init.d/S01network"

# 6.6 生成 Dropbear SSH 主机密钥
sudo "${ROOTFS_DIR}/sbin/dropbearkey" -t rsa -f "${ROOTFS_DIR}/etc/dropbear/dropbear_rsa_host_key"

# 6.7 SSH 开机脚本 S02ssh
cat > "${ROOTFS_DIR}/etc/init.d/S02ssh" <<'EOF'
#!/bin/sh
echo "Start Dropbear SSH Server..."
/sbin/dropbear -E
EOF
chmod +x "${ROOTFS_DIR}/etc/init.d/S02ssh"

# 6.8 inetd 配置 telnet
cat > "${ROOTFS_DIR}/etc/inetd.conf" <<EOF
telnet   stream  tcp     nowait  root    /usr/sbin/telnetd telnetd
EOF

# 6.9 服务端口映射
cat > "${ROOTFS_DIR}/etc/services" <<EOF
telnet          23/tcp
ssh             22/tcp
EOF

# 6.10 Telnet 开机脚本 S03telnet
cat > "${ROOTFS_DIR}/etc/init.d/S03telnet" <<'EOF'
#!/bin/sh
echo "Start Telnet Server..."
/usr/sbin/inetd
EOF
chmod +x "${ROOTFS_DIR}/etc/init.d/S03telnet"

echo "[6/7] ✅ 所有配置文件写入完成"
echo

####################################################
# 步骤7：制作 ext4 镜像
####################################################
echo "[7/7] 制作 ${IMG_SIZE}MB ext4 镜像..."
dd if=/dev/zero of="${IMG}" bs=1M count="${IMG_SIZE}"
mkfs.ext4 -F "${IMG}"

sudo mount "${IMG}" /mnt
sudo cp -rf "${ROOTFS_DIR}"/* /mnt/
sudo umount /mnt

echo "[7/7] 完成，镜像文件：${IMG}"
echo
echo "🎉 全部流程执行完毕！rootfs.ext4 制作成功"
echo "👉 QEMU 启动示例："
echo 'qemu-system-aarch64 \
-M virt \
-cpu cortex-a53 \
-m 1G \
-nographic \
-kernel ./zImage \
-dtb ./xxx.dtb \
-drive file=rootfs.ext4,format=raw,if=virtio \
-net nic,model=virtio \
-net user,hostfwd=tcp::2222-:22,hostfwd=tcp::2323-:23 \
-append "root=/dev/vda rw console=ttyAMA0,115200 init=/init"'
echo
echo "👉 宿主机登录 & 文件传输："
echo "SSH 登录: ssh -p 2222 root@127.0.0.1"
echo "SCP 上传: scp -P 2222 本地文件 root@127.0.0.1:/tmp/"
echo "SCP 下载: scp -P 2222 root@127.0.0.1:/tmp/目标文件  ./ "
echo "Telnet 登录: telnet 127.0.0.1 2323"
