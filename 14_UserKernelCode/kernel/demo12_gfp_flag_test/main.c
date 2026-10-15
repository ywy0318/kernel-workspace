#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/init.h>

static char *buf1,*buf2;
static int __init gfp_init(void)
{
    buf1 = kmalloc(256, GFP_KERNEL);
    buf2 = kmalloc(256, GFP_ATOMIC);
    if (!buf1 || !buf2) {
        kfree(buf1);
        kfree(buf2);
        return -ENOMEM;
    }
    pr_info("demo12 GFP_KERNEL:%p GFP_ATOMIC:%p\n", buf1, buf2);
    return 0;
}

static void __exit gfp_exit(void)
{
    kfree(buf1);
    kfree(buf2);
    pr_info("demo12 free\n");
}

module_init(gfp_init);
module_exit(gfp_exit);
MODULE_LICENSE("GPL");
