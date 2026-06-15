cd ~/workspace/00_EnvScripts

# 直接写死一行，不换行，最稳
cat > create_workspace_dirs.sh <<'EOF'
#!/bin/bash
echo "====================================="
echo "  创建嵌入式学习目录（含qemu-debootstrap）"
echo "====================================="

# 全部写在一行，bash 100% 正常展开
mkdir -p ~/workspace/{00_EnvScripts,01_Uboot,02_LinuxKernel,03_DtsDev,04_ManualRootFS,05_BusyBox,06_Buildroot,07_Yocto,08_QemuRun,09_KernelDebugTest,10_PerfOpt,11_QemuDebootstrapRootFS}

echo "✅ 目录创建完成"
ls -d ~/workspace/*
EOF

chmod +x create_workspace_dirs.sh

# 直接运行
./create_workspace_dirs.sh
