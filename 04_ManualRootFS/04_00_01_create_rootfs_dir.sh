#!/bin/bash
# 步骤1：创建rootfs基础目录

echo "[1/5] 创建rootfs目录结构..."
mkdir -p rootfs/{bin,dev,etc,lib,proc,sys,tmp,var,run}
chmod 1777 rootfs/tmp

echo "[1/5] 完成"
