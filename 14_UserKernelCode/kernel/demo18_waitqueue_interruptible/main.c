#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/wait.h>
#include <linux/kthread.h>
#include <linux/init.h>

static wait_queue_head_t wq;
static int condition = 0;
static struct task_struct *wait_thr;

static int wait_thread(void *arg)
{
	int ret;
	pr_info("demo18 wait_event_interruptible start\n");
	ret = wait_event_interruptible(wq, condition != 0);
	if (ret == -ERESTARTSYS) {
		pr_info("demo18 wait interrupted by signal\n");
	} else {
		pr_info("demo18 wakeup normally\n");
	}
	return 0;   // 删掉 do_exit(0);
}

static int __init wq_int_init(void)
{
	init_waitqueue_head(&wq);
	wait_thr = kthread_run(wait_thread, NULL, "demo18_wait");
	pr_info("demo18 interruptible wait start\n");
	return 0;
}

static void __exit wq_int_exit(void)
{
	condition = 1;
	wake_up(&wq);
	pr_info("demo18 exit\n");
}

module_init(wq_int_init);
module_exit(wq_int_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo18 wait_event_interruptible");
