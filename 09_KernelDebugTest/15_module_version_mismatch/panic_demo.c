#include <linux/module.h>
#include <linux/kernel.h>

static int __init demo_init(void)
{
    pr_info("normal module, compile with different kernel\n");
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
