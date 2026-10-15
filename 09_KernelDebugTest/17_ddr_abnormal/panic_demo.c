#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/io.h>

static int __init demo_init(void)
{
    void __iomem *ddr_bad = ioremap(0x800000000, 0x10000); //非法DDR地址
    pr_info("access invalid ddr region\n");
    ioread32(ddr_bad);
    iounmap(ddr_bad);
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
