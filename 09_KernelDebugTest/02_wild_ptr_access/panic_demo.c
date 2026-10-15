#include <linux/module.h>
#include <linux/kernel.h>

static int __init demo_init(void)
{
    int *p = (int *)0x11223344; // 随机无效地址野指针
    pr_info("trigger wild pointer access\n");
    *p = 0x5678;
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
