#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/wait.h>
#include <linux/kthread.h>
#include <linux/init.h>
#include <linux/delay.h>   // msleep 头文件

static wait_queue_head_t wq;
static int condition = 0;
static struct task_struct *wait_thr, *wake_thr;

static int wait_thread(void *arg)
{
	pr_info("demo16 wait thread: waiting\n");
	// 等待条件 condition != 0
	wait_event(wq, condition != 0);
	pr_info("demo16 wait thread wakeup, condition=%d\n", condition);

	return 0;   // 删除 do_exit(0);
}

static int wake_thread(void *arg)
{
	msleep(3000);
	condition = 1;
	wake_up(&wq);
	pr_info("demo16 wake thread trigger wake_up\n");

	return 0;   // 删除 do_exit(0);
}

static int __init wq_basic_init(void)
{
	init_waitqueue_head(&wq);
	wait_thr = kthread_run(wait_thread, NULL, "demo16_wait");
	wake_thr = kthread_run(wake_thread, NULL, "demo16_wake");
	pr_info("demo16 waitqueue basic start\n");
	return 0;
}

static void __exit wq_basic_exit(void)
{
	// 可选：kthread_stop 安全回收线程（如果你改成常驻循环版本）
	pr_info("demo16 exit\n");
}

module_init(wq_basic_init);
module_exit(wq_basic_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo16 waitqueue basic");

