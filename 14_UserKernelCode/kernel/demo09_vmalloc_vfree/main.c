#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/vmalloc.h>
#include <linux/init.h>

static char *vbuf;
static int __init vmalloc_demo_init(void)
{
    vbuf = vmalloc(1024*1024);
    if (!vbuf) return -ENOMEM;
    pr_info("demo09 vmalloc virt addr: %p\n", vbuf);
    vbuf[0] = 'X';
    return 0;
}

static void __exit vmalloc_demo_exit(void)
{
    vfree(vbuf);
    pr_info("demo09 vfree done\n");
}

module_init(vmalloc_demo_init);
module_exit(vmalloc_demo_exit);
MODULE_LICENSE("GPL");
