#include <linux/module.h>
#include <linux/kernel.h>

static int __init demo_init(void)
{
    int arr[4] = {1,2,3,4};
    pr_info("trigger array out of bound\n");
    arr[100] = 999; // 内核栈数组越界
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
