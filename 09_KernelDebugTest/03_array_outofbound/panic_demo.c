#include <linux/module.h>
#include <linux/kernel.h>

static int __init demo_init(void)
{
    int arr[4] = {1,2,3,4};
    volatile unsigned long *p;
    pr_info("trigger array out of bound\n");

    p = (volatile unsigned long *)&arr[0];
    // 往栈后方写入非法地址，volatile强制保留内存写入
    p[80] = 0xdeadbeefdeadbeefUL;

    // 读取回来，防止编译器完全优化掉
    pr_info("write value: 0x%lx\n", p[80]);
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");


