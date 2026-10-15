#include <linux/module.h>
#include <linux/kernel.h>

static noinline int recurse(int val)
{
    char buf[1024];
    buf[0] = val & 0xff;
    return recurse(val + 1); //无限递归，耗尽内核栈
}

static int __init demo_init(void)
{
    pr_info("trigger kernel stack overflow\n");
    recurse(0);
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
