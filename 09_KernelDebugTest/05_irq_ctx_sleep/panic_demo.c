#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/delay.h>

static irqreturn_t fake_irq_handler(int irq, void *dev_id)
{
    pr_info("in irq handler, try msleep!\n");
    msleep(1000); // 中断上下文不能sleep，触发panic
    return IRQ_HANDLED;
}

static int __init demo_init(void)
{
    // 注册一个虚拟中断，直接在handler里sleep
    request_irq(10, fake_irq_handler, IRQF_SHARED, "irq_sleep_demo", NULL);
    // 手动调用中断函数模拟触发
    fake_irq_handler(10, NULL);
    return 0;
}

static void __exit demo_exit(void)
{
    free_irq(10, NULL);
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
