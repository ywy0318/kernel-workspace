#!/bin/bash
# 14_97_kernel_create_demo_dirs.sh
# 在 ./kernel/ 下创建34个linux6.18内核模块实验目录
DEST_ROOT="./kernel"

# 定义全部34项: 英文目录名
DIR_LIST=(
# 阶段1：入门基础（模块框架、打印、参数、proc）
demo01_simple_module
demo02_module_param
demo03_read_mostly_var
demo04_proc_readonly
demo05_proc_rw
demo06_sysfs_kobject

# 阶段2：内存管理
demo07_kmalloc_kfree
demo08_kzalloc
demo09_vmalloc_vfree
demo10_alloc_page
demo11_kmem_cache
demo12_gfp_flag_test

# 阶段3：同步原语
demo13_spinlock
demo14_mutex
demo15_semaphore
demo16_waitqueue_basic
demo17_completion
demo18_waitqueue_interruptible

# 阶段4：内核线程、工作队列、定时器、下半部
demo19_kthread
demo20_workqueue
demo21_delayed_work
demo22_timer_list
demo23_hrtimer

# 阶段5：字符设备驱动
demo24_cdev_simple
demo25_cdev_rw
demo26_cdev_blocking_read
demo27_cdev_poll

# 阶段6：进阶 中断、DTS平台驱动
demo28_tasklet
demo29_irq_workqueue
demo30_platform_driver_dts
demo31_platform_ioremap

# 阶段7：拔高调试实验
demo32_memblock_info
demo33_traverse_page
demo34_traverse_task
)

# 创建根目录
mkdir -p "${DEST_ROOT}"

# 循环创建每个demo目录
for dirname in "${DIR_LIST[@]}"; do
    mkdir -p "${DEST_ROOT}/${dirname}"
    echo "created: ${DEST_ROOT}/${dirname}"
done

echo -e "\n✅ 全部34个内核实验目录创建完成，路径: ${DEST_ROOT}"
