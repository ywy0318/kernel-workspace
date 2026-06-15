sudo apt update -y
sudo apt upgrade -y

# 基础编译工具
sudo apt install -y build-essential git make cmake autoconf automake libtool pkg-config

# 文本/工具
sudo apt install -y tree curl wget net-tools iputils-ping htop

# 内核 / U-Boot 编译依赖
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
sudo apt install -y libncurses-dev flex bison libssl-dev bc libelf-dev
sudo apt install -y python3 python3-pip

# LLVM / Clang 编译环境
sudo apt install -y clang lld llvm

# QEMU 虚拟机
sudo apt install -y qemu-system-arm qemu-system-x86 qemu-utils

# 设备树 DTS 编译工具
sudo apt install -y device-tree-compiler

# 内核调试工具
sudo apt install -y gdb gdb-multiarch crash elfutils patchutils

# busybox / buildroot 依赖
sudo apt install -y unzip bzip2 cpio rsync

# 调试Oops/Panic必备
sudo apt install -y libdw-dev libunwind-dev

echo "====================================="
echo "  嵌入式开发环境安装完成 ✅"
echo "====================================="
