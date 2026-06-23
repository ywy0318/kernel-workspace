#!/bin/bash
# 步骤3：创建/dev下必要节点

echo "[3/5] 创建设备节点（sudo）..."
sudo mknod rootfs/dev/console c 5 1
sudo mknod rootfs/dev/null  c 1 3

echo "[3/5] 完成"
