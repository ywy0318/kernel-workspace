#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/spinlock.h>

spinlock_t test_lock;

static int __init demo_init(void)
{
    pr_info("take spinlock, return without unlock\n");
    spin_lock(&test_lock);
    return 0; //拿到锁，直接return，没有spin_unlock
}

static void __exit demo_exit(void)
{
    spin_unlock(&test_lock);
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
