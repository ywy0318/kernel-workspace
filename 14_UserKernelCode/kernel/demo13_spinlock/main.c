#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/spinlock.h>
#include <linux/kthread.h>
#include <linux/init.h>

static spinlock_t lock;
static int share_val = 0;
static struct task_struct *thr1,*thr2;

static int thread_fn(void *arg)
{
    int i;
    for(i=0;i<10000;i++){
        spin_lock(&lock);
        share_val++;
        spin_unlock(&lock);
    }
    pr_info("demo13 thread done\n");
    do_exit(0);
}

static int __init spin_init(void)
{
    spin_lock_init(&lock);
    thr1 = kthread_run(thread_fn, NULL, "demo13_thr1");
    thr2 = kthread_run(thread_fn, NULL, "demo13_thr2");
    pr_info("demo13 spinlock start\n");
    return 0;
}

static void __exit spin_exit(void)
{
    pr_info("demo13 final share_val=%d\n", share_val);
}

module_init(spin_init);
module_exit(spin_exit);
MODULE_LICENSE("GPL");
