#!/bin/bash
echo "====================================="
echo "  创建嵌入式学习目录（含qemu-debootstrap、流程图目录）"
echo "====================================="

# 全部写在一行，bash 100% 正常展开，末尾追加 12_DiagramDrawio
mkdir -p ~/workspace/{00_EnvScripts,01_Uboot,02_LinuxKernel,03_DtsDev,04_ManualRootFS,05_BusyBox,06_Buildroot,07_Yocto,08_QemuRun,09_KernelDebugTest,10_PerfOpt,11_QemuDebootstrapRootFS,12_DiagramDrawio,13_KernelDebugTools}

echo "✅ 目录创建完成"
ls -d ~/workspace/*
