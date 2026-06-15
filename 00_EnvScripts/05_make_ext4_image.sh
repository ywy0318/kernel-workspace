#!/bin/bash
# 步骤5：制作ext4镜像

IMG="rootfs.ext4"
SIZE=64

echo "[5/5] 制作${SIZE}MB ext4镜像..."
dd if=/dev/zero of="${IMG}" bs=1M count=${SIZE}
mkfs.ext4 "${IMG}"

sudo mount "${IMG}" /mnt
sudo cp -rf rootfs/* /mnt/
sudo umount /mnt

echo "[5/5] 完成，镜像：${IMG}"
