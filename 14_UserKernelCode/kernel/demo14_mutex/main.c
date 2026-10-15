#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/mutex.h>
#include <linux/kthread.h>
#include <linux/init.h>

static struct mutex mtx;
static int share_val = 0;
static struct task_struct *thr1,*thr2;

static int thread_fn(void *arg)
{
    int i;
    for(i=0;i<10000;i++){
        mutex_lock(&mtx);
        share_val++;
        mutex_unlock(&mtx);
    }
    pr_info("demo14 thread done\n");
    do_exit(0);
}

static int __init mutex_init_mod(void)
{
    mutex_init(&mtx);
    thr1 = kthread_run(thread_fn, NULL, "demo14_thr1");
    thr2 = kthread_run(thread_fn, NULL, "demo14_thr2");
    pr_info("demo14 mutex start\n");
    return 0;
}

static void __exit mutex_exit_mod(void)
{
    pr_info("demo14 final share_val=%d\n", share_val);
}

module_init(mutex_init_mod);
module_exit(mutex_exit_mod);
MODULE_LICENSE("GPL");
