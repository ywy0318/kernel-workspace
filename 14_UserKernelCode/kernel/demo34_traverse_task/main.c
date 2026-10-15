#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/init.h>
#include <linux/rculist.h>

static int __init traverse_task_init(void)
{
    struct task_struct *task;
    int cnt = 0;
    pr_info("demo34: traverse task start\n");

    rcu_read_lock();
    for_each_process(task) {
        pr_info("pid:%d comm:%s\n", task->pid, task->comm);
        cnt++;
        if (cnt >= 10)
            break;
    }
    rcu_read_unlock();

    pr_info("demo34: traverse task done\n");
    return 0;
}

static void __exit traverse_task_exit(void)
{
    pr_info("demo34: module unload\n");
}

module_init(traverse_task_init);
module_exit(traverse_task_exit);
MODULE_LICENSE("GPL");
