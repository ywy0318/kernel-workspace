#!/bin/bash

#BUILDROOT_DIR="buildroot-2023.02.9"
BUILDROOT_DIR="buildroot-2025.02"
IMG_OUT_DIR="${BUILDROOT_DIR}/output/images"
ROOTFS_IMAGE="${IMG_OUT_DIR}/rootfs.ext4"
UBOOT_BIN="${IMG_OUT_DIR}/u-boot.bin"
KERNEL_IMG="${IMG_OUT_DIR}/Image"
# 直接输出到固件统一目录，不再留在脚本同级
SD_IMG="${IMG_OUT_DIR}/sdcard.img"
SD_IMG_SIZE="128M"

echo -e "\n===== 强制干净环境单线程完整编译 + 自动生成整块SD镜像 =====\n"

# 编译阶段无需root
bash -c "
  cd $BUILDROOT_DIR
  unset LD_LIBRARY_PATH
  unset MAKEFLAGS
  unset MFLAGS
  unset JOB_SERVER_FIFO
  make -j1
"
ret_code=$?
if [ ${ret_code} -ne 0 ]; then
    echo -e "\n❌ make编译执行失败！"
    exit 1
fi

# 依次校验编译产出
check_fail=0
[ ! -f "$ROOTFS_IMAGE" ] && echo "❌ rootfs.ext4 缺失" && check_fail=1
[ ! -f "$UBOOT_BIN" ]     && echo "❌ u-boot.bin 缺失" && check_fail=1
[ ! -f "$KERNEL_IMG" ]    && echo "❌ 内核Image镜像缺失" && check_fail=1

if [ ${check_fail} -ne 0 ]; then
    echo -e "\n❌ 关键固件文件缺失，终止执行"
    exit 1
fi

# 空间校验：统计内核+rootfs总占用，判断128M是否充足
TOTAL_BYTES=$(du -bs "${KERNEL_IMG}" "${ROOTFS_IMAGE}" | awk '{sum+=$1} END{print sum}')
# 预留16MB U-Boot+分区表+日志冗余
REQUIRE_BYTES=$(( TOTAL_BYTES + 16*1024*1024 ))
LIMIT_BYTES=$(( 128*1024*1024 ))

if [ ${REQUIRE_BYTES} -gt ${LIMIT_BYTES} ]; then
    echo "❌ 固件总大小${REQUIRE_BYTES}字节，超出128M容量限制，扩容镜像！"
    exit 1
fi
echo "✅ 固件总大小校验通过，128MB空间足够容纳"

echo -e "\n===== 开始组装整块SD卡镜像 ${SD_IMG} ====="
set -e

# 覆盖旧镜像
rm -f "${SD_IMG}"
dd if=/dev/zero of="${SD_IMG}" bs=1 count=0 seek="${SD_IMG_SIZE}"

sudo parted -s "${SD_IMG}" mklabel msdos
sudo parted -s "${SD_IMG}" mkpart primary ext4 16MiB 100%

LOOP_DEV=$(sudo losetup -f)
sudo losetup "${LOOP_DEV}" "${SD_IMG}"
sudo partprobe "${LOOP_DEV}"

# QEMU AArch64标准偏移写入U-Boot
sudo dd if="${UBOOT_BIN}" of="${LOOP_DEV}" bs=1K seek=8 conv=notrunc

sudo mkfs.ext4 -F "${LOOP_DEV}p1"

mkdir -p tmp_mnt
sudo mount "${LOOP_DEV}p1" tmp_mnt
sudo cp "${KERNEL_IMG}" tmp_mnt/
sudo mount -o loop "${ROOTFS_IMAGE}" tmp_mnt
# 容错卸载
sudo umount tmp_mnt || true
sudo losetup -d "${LOOP_DEV}" || true
rmdir tmp_mnt 2>/dev/null || true

echo -e "\n========================================"
echo "✅ 全部流程执行完毕！所有固件统一输出到images目录"
echo "U-Boot：${UBOOT_BIN}"
echo "内核镜像：${KERNEL_IMG}"
echo "根文件系统：${ROOTFS_IMAGE}"
echo "整卡SD镜像：${SD_IMG}"
echo "========================================"
exit 0
