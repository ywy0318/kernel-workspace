#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/completion.h>
#include <linux/kthread.h>
#include <linux/init.h>
#include <linux/delay.h>   // msleep头文件

static struct completion comp;
static struct task_struct *wait_thr, *comp_thr;

static int wait_thread(void *arg)
{
	pr_info("demo17 wait for completion\n");
	wait_for_completion(&comp);
	pr_info("demo17 completed!\n");
	return 0;   // 删除 do_exit(0);
}

static int comp_thread(void *arg)
{
	msleep(3000);
	complete(&comp);
	pr_info("demo17 call complete()\n");
	return 0;   // 删除 do_exit(0);
}

static int __init comp_init(void)
{
	init_completion(&comp);
	wait_thr = kthread_run(wait_thread, NULL, "demo17_wait");
	comp_thr = kthread_run(comp_thread, NULL, "demo17_comp");
	pr_info("demo17 completion demo start\n");
	return 0;
}

static void __exit comp_exit(void)
{
	pr_info("demo17 exit\n");
}

module_init(comp_init);
module_exit(comp_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo17 completion basic");

