#!/bin/bash
# 09_98_create_panic_dirs.sh
# 批量创建20个linux内核panic测试模块目录

DIRS=(
"01_null_ptr_deref"
"02_wild_ptr_access"
"03_array_outofbound"
"04_illegal_addr_access"
"05_irq_ctx_sleep"
"06_spinlock_deadlock"
"07_stack_overflow"
"08_dts_addr_wrong"
"09_driver_probe_fail"
"10_kernel_access_user_ptr"
"11_spinlock_no_unlock_return"
"12_empty_syscall"
"13_irq_num_wrong"
"14_vfs_mount_rootfs_fail"
"15_module_version_mismatch"
"16_clock_abnormal"
"17_ddr_abnormal"
"18_reg_access_err"
"19_kernel_deadloop"
"20_oom_trigger"
)

echo "===== Start create 20 panic test dirs ====="
for d in "${DIRS[@]}";do
    mkdir -p ./$d
    echo "Created: ./$d"
done
echo "===== All dirs created finished ====="
