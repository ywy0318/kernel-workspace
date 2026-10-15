#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>

static int __init demo_init(void)
{
    void *p;
    pr_info("trigger oom, keep alloc memory\n");
    while(1)
    {
        p = kmalloc(1024*1024, GFP_KERNEL); //循环不断申请内存，触发OOM
    }
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
