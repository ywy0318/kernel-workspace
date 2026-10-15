#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kthread.h>
#include <linux/init.h>

static struct task_struct *thr;

static int kthread_fn(void *arg)
{
    while(!kthread_should_stop()){
        pr_info("demo19 kthread running\n");
        msleep(2000);
    }
    pr_info("demo19 kthread exit\n");
    return 0;
}

static int __init kthread_mod_init(void)
{
    thr = kthread_run(kthread_fn, NULL, "demo19_thr");
    pr_info("demo19 kthread created\n");
    return 0;
}

static void __exit kthread_mod_exit(void)
{
    kthread_stop(thr);
    pr_info("demo19 kthread stopped\n");
}

module_init(kthread_mod_init);
module_exit(kthread_mod_exit);
MODULE_LICENSE("GPL");
