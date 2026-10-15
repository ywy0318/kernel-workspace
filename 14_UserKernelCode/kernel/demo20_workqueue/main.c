#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/workqueue.h>
#include <linux/init.h>

static struct work_struct work;

static void work_handler(struct work_struct *w)
{
    pr_info("demo20 workqueue handler run\n");
}

static int __init wq_mod_init(void)
{
    INIT_WORK(&work, work_handler);
    schedule_work(&work);
    pr_info("demo20 work scheduled\n");
    return 0;
}

static void __exit wq_mod_exit(void)
{
    pr_info("demo20 exit\n");
}

module_init(wq_mod_init);
module_exit(wq_mod_exit);
MODULE_LICENSE("GPL");
