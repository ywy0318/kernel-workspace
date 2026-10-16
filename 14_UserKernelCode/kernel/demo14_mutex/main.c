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
	pid_t tid = current->pid;
	pr_info("demo14 thread %d start\n", tid);

	for(i=0;i<10000;i++){
		mutex_lock(&mtx);
		share_val++;
		mutex_unlock(&mtx);
	}
	// 打印线程ID、i、share_val
	pr_info("demo14 thread %d done, i=%d, share_val=%d\n", tid, i, share_val);
	return 0;   // 删掉 do_exit(0);
}

static int __init mutex_init_mod(void)
{
	mutex_init(&mtx);
	thr1 = kthread_run(thread_fn, NULL, "demo14_thr1");
	if (IS_ERR(thr1)) {
		pr_err("create thr1 failed\n");
		thr1 = NULL;
	} else {
		pr_info("demo14 create thr1 pid=%d\n", thr1->pid);
	}

	thr2 = kthread_run(thread_fn, NULL, "demo14_thr2");
	if (IS_ERR(thr2)) {
		pr_err("create thr2 failed\n");
		thr2 = NULL;
	} else {
		pr_info("demo14 create thr2 pid=%d\n", thr2->pid);
	}

	pr_info("demo14 mutex start\n");
	return 0;
}

static void __exit mutex_exit_mod(void)
{
	// 一次性版本：线程跑完自动销毁，不要调用kthread_stop，否则Oops
	pr_info("demo14 final share_val=%d\n", share_val);
}

module_init(mutex_init_mod);
module_exit(mutex_exit_mod);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo14 mutex test");
