#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/spinlock.h>

spinlock_t lock_a;
spinlock_t lock_b;

static int __init demo_init(void)
{
    pr_info("spinlock deadlock start\n");
    spin_lock(&lock_a);
    spin_lock(&lock_b);
    // 反向拿锁造成死锁，这里简化模拟
    spin_lock(&lock_a);
    spin_unlock(&lock_b);
    spin_unlock(&lock_a);
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
