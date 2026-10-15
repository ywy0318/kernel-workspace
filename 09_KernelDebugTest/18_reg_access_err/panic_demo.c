#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/io.h>

static int __init demo_init(void)
{
    void __iomem *reg = ioremap(0x00000000, 0x1000);
    pr_info("access reserved register\n");
    iowrite32(0xffffffff, reg + 0x100);
    iounmap(reg);
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
