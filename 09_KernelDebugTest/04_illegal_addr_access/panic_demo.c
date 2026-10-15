#include <linux/module.h>
#include <linux/kernel.h>

static int __init demo_init(void)
{
    char *bad_addr = (char *)0x0;
    pr_info("trigger illegal address access\n");
    bad_addr[0x1000] = 0xaa;
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
