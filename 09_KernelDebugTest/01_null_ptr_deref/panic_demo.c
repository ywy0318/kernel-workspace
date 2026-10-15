#include <linux/module.h>
#include <linux/kernel.h>

static int __init demo_init(void)
{
    int *p = NULL;
    pr_info("trigger null pointer deref\n");
    *p = 0x1234; // 空指针写，直接oops/panic
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
