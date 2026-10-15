#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/semaphore.h>
#include <linux/kthread.h>
#include <linux/init.h>

static struct semaphore sem;
static int share_val = 0;
static struct task_struct *thr1,*thr2,*thr3;

static int thread_fn(void *arg)
{
    int i;
    for(i=0;i<5000;i++){
        down(&sem);
        share_val++;
        up(&sem);
    }
    pr_info("demo15 thread done\n");
    do_exit(0);
}

static int __init sem_init_mod(void)
{
    sema_init(&sem, 1);
    thr1 = kthread_run(thread_fn, NULL, "demo15_thr1");
    thr2 = kthread_run(thread_fn, NULL, "demo15_thr2");
    thr3 = kthread_run(thread_fn, NULL, "demo15_thr3");
    pr_info("demo15 semaphore start\n");
    return 0;
}

static void __exit sem_exit_mod(void)
{
    pr_info("demo15 final share_val=%d\n", share_val);
}

module_init(sem_init_mod);
module_exit(sem_exit_mod);
MODULE_LICENSE("GPL");
