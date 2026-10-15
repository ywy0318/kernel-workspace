#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/init.h>

static char *buf;
static int __init kmalloc_demo_init(void)
{
    buf = kmalloc(1024, GFP_KERNEL);
    if (!buf) return -ENOMEM;
    pr_info("demo07 kmalloc virt addr: %p\n", buf);
    buf[0] = 'A';
    return 0;
}

static void __exit kmalloc_demo_exit(void)
{
    kfree(buf);
    pr_info("demo07 kfree done\n");
}

module_init(kmalloc_demo_init);
module_exit(kmalloc_demo_exit);
MODULE_LICENSE("GPL");
