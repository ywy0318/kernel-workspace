#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/io.h>

static int __init demo_init(void)
{
    void __iomem *base = ioremap(0xFFFF00000, 0x1000); //错误物理地址，dts写错场景
    pr_info("access wrong dts reg addr\n");
    iowrite32(0x1234, base);
    iounmap(base);
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
