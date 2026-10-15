#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/hrtimer.h>
#include <linux/init.h>

static struct hrtimer hr_timer;
static enum hrtimer_restart hrt_handler(struct hrtimer *timer)
{
    pr_info("demo23 hrtimer trigger\n");
    return HRTIMER_NORESTART;
}

static int __init hrt_init(void)
{
    ktime_t kt = ktime_set(2,0);
    hrtimer_init(&hr_timer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);
    hr_timer.function = hrt_handler;
    hrtimer_start(&hr_timer, kt, HRTIMER_MODE_REL);
    pr_info("demo23 hrtimer start 2s\n");
    return 0;
}

static void __exit hrt_exit(void)
{
    hrtimer_cancel(&hr_timer);
    pr_info("demo23 hrtimer cancel\n");
}

module_init(hrt_init);
module_exit(hrt_exit);
MODULE_LICENSE("GPL");
