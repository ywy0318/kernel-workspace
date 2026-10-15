#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/init.h>

static void tasklet_handler(struct tasklet_struct *t)
{
    pr_info("demo28 tasklet run\n");
}
DECLARE_TASKLET(demo_tl, tasklet_handler);

static int __init tasklet_init_mod(void)
{
    tasklet_schedule(&demo_tl);
    pr_info("demo28 tasklet scheduled\n");
    return 0;
}

static void __exit tasklet_exit_mod(void)
{
    tasklet_kill(&demo_tl);
    pr_info("demo28 tasklet killed\n");
}

module_init(tasklet_init_mod);
module_exit(tasklet_exit_mod);
MODULE_LICENSE("GPL");
