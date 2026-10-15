#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/clk.h>

static int __init demo_init(void)
{
    struct clk *clk = NULL;
    pr_info("try access invalid clock\n");
    clk_enable(clk); //空时钟，时钟子系统异常
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
