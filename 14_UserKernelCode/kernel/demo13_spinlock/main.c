#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/spinlock.h>
#include <linux/kthread.h>

static spinlock_t lock;
static int share_val = 0;
static struct task_struct *thr1,*thr2;

static int thread_fn(void *arg)
{
	int i;
	pid_t tid = current->pid; // 获取当前内核线程id

	pr_info("demo13 thread %d start\n", tid);

	// 常驻循环：kthread_should_stop() 检测停止标志
	while (!kthread_should_stop()) {
		for(i = 0; i < 10000; i++){
			spin_lock(&lock);
			share_val++;
			spin_unlock(&lock);
		}
	}
	// 线程即将退出，打印信息
	pr_info("demo13 thread %d done, i=%d, share_val=%d\n", tid, i, share_val);
	return 0;
}

static int __init spin_init(void)
{
	spin_lock_init(&lock);
	thr1 = kthread_run(thread_fn, NULL, "demo13_thr1");
	if (IS_ERR(thr1)) {
		pr_err("create thr1 failed\n");
		thr1 = NULL;
	} else {
		pr_info("demo13 create thr1 pid=%d\n", thr1->pid);
	}

	thr2 = kthread_run(thread_fn, NULL, "demo13_thr2");
	if (IS_ERR(thr2)) {
		pr_err("create thr2 failed\n");
		thr2 = NULL;
	} else {
		pr_info("demo13 create thr2 pid=%d\n", thr2->pid);
	}

	pr_info("demo13 spinlock start\n");
	return 0;
}

static void __exit spin_exit(void)
{
	// 只有指针有效，才调用kthread_stop
	if (thr1) {
		kthread_stop(thr1);
		thr1 = NULL;
	}
	if (thr2) {
		kthread_stop(thr2);
		thr2 = NULL;
	}
	pr_info("demo13 final share_val=%d\n", share_val);
}

module_init(spin_init);
module_exit(spin_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo13 spinlock test");


