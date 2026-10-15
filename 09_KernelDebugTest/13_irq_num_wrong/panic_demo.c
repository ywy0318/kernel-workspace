#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>

static irqreturn_t dummy_handler(int irq, void *dev_id)
{
    return IRQ_HANDLED;
}

static int __init demo_init(void)
{
    pr_info("request invalid irq number\n");
    request_irq(0xFFFF, dummy_handler, IRQF_SHARED, "bad_irq", NULL); //非法中断号
    return 0;
}

static void __exit demo_exit(void)
{
    free_irq(0xFFFF, NULL);
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
