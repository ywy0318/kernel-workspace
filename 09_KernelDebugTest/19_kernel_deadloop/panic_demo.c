#include <linux/module.h>
#include <linux/kernel.h>

static int __init demo_init(void)
{
    pr_info("enter kernel dead loop\n");
    while(1){
        // 关抢占，死循环，CPU卡死
    }
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
