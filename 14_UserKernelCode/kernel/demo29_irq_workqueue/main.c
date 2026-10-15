#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/workqueue.h>
#include <linux/init.h>

static struct work_struct work;
static void work_handler(struct work_struct *w)
{
    pr_info("demo29 workqueue as irq bottom half\n");
}

static irqreturn_t fake_irq_handler(int irq, void *arg)
{
    pr_info("demo29 fake irq top half\n");
    schedule_work(&work);
    return IRQ_HANDLED;
}

static int __init irq_work_init(void)
{
    INIT_WORK(&work, work_handler);
    /* 这里只是演示函数结构，真实硬件需要request_irq绑定硬件中断号 */
    pr_info("demo29 irq+workqueue demo loaded\n");
    return 0;
}

static void __exit irq_work_exit(void)
{
    pr_info("demo29 exit\n");
}

module_init(irq_work_init);
module_exit(irq_work_exit);
MODULE_LICENSE("GPL");
