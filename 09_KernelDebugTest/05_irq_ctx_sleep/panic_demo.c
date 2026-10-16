#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/delay.h>
#include <asm/irq.h>

static int __init demo_init(void)
{
    unsigned long flags;
    pr_info("try sleep in irq context\n");
    // 关中断，此时处于类似中断上下文环境
    local_irq_save(flags);
    // 在关中断的上下文调用msleep，内核检测到非法休眠，直接BUG/Oops
    msleep(1000);
    local_irq_restore(flags);
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");

