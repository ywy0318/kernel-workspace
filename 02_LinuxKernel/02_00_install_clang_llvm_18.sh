#!/bin/bash
# 02_00_install_clang_llvm_18.sh
# 功能：在Ubuntu上安装Clang/LLVM 18，并设置为默认版本（修复版，解决卡住问题）

set -e

echo -e "\n=== 开始安装 Clang/LLVM 18 工具链（修复版） ==="

# 1. 清理旧配置（如果之前的脚本失败了）
echo "清理旧配置..."
sudo rm -f /etc/apt/sources.list.d/llvm.list
sudo rm -f /usr/share/keyrings/llvm-archive-keyring.gpg

# 2. 添加LLVM官方密钥（使用推荐的 gpg --dearmor 方式）
echo "1/3 添加LLVM官方密钥..."
wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/llvm-archive-keyring.gpg > /dev/null

# 3. 添加LLVM官方源（或国内镜像源，二选一）
echo "2/3 添加LLVM软件源..."
# 方案A：官方源（如果国内访问不稳定，换成方案B）
echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main" | sudo tee /etc/apt/sources.list.d/llvm.list

# 方案B：清华镜像源（网络不好时用，注释掉上面的方案A，打开下面的方案B）
# echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/jammy/ llvm-toolchain-jammy-18 main" | sudo tee /etc/apt/sources.list.d/llvm.list

# 4. 更新软件列表并安装
echo "3/3 更新软件包列表并安装clang-18..."
sudo apt update
sudo apt install -y clang-18 lld-18 llvm-18

# 5. 设置默认版本
echo "设置clang-18为默认版本..."
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100
sudo update-alternatives --install /usr/bin/ld.lld ld.lld /usr/bin/ld.lld-18 100

echo -e "\n=== 安装完成，当前版本信息 ==="
clang --version
ld.lld --version

echo -e "\n✅ 工具链安装配置完成！"
