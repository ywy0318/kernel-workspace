#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/workqueue.h>
#include <linux/init.h>

static struct delayed_work dwork;

static void dw_handler(struct work_struct *w)
{
    pr_info("demo21 delayed work run\n");
}

static int __init dw_init(void)
{
    INIT_DELAYED_WORK(&dwork, dw_handler);
    schedule_delayed_work(&dwork, msecs_to_jiffies(3000));
    pr_info("demo21 delayed work scheduled, 3s later\n");
    return 0;
}

static void __exit dw_exit(void)
{
    cancel_delayed_work_sync(&dwork);
    pr_info("demo21 delayed work canceled\n");
}

module_init(dw_init);
module_exit(dw_exit);
MODULE_LICENSE("GPL");
