#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/init.h>

static char *buf;
static int __init kzalloc_demo_init(void)
{
    buf = kzalloc(1024, GFP_KERNEL);
    if (!buf) return -ENOMEM;
    pr_info("demo08 kzalloc virt addr: %p, buf[0]=%d\n", buf, buf[0]);
    return 0;
}

static void __exit kzalloc_demo_exit(void)
{
    kfree(buf);
    pr_info("demo08 kfree done\n");
}

module_init(kzalloc_demo_init);
module_exit(kzalloc_demo_exit);
MODULE_LICENSE("GPL");
