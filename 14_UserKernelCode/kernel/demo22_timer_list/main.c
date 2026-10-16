#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/timer.h>
#include <linux/init.h>

static struct timer_list timer;

static void timer_callback(struct timer_list *t)
{
	pr_info("demo22 timer callback triggered\n");
}

static int __init timer_init(void)
{
	timer_setup(&timer, timer_callback, 0);
	mod_timer(&timer, jiffies + msecs_to_jiffies(2000));
	pr_info("demo22 timer set, 2s\n");
	return 0;
}

static void __exit timer_exit(void)
{
	timer_delete_sync(&timer);   // 重点：替换 del_timer_sync → timer_delete_sync
	pr_info("demo22 timer deleted\n");
}

module_init(timer_init);
module_exit(timer_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo22 timer_list");

