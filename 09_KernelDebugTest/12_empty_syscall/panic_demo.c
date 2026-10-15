#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/syscalls.h>

// 注册一个空的系统调用
asmlinkage long empty_syscall(void)
{
    pr_info("empty syscall invoked\n");
    return 0;
}

static int __init demo_init(void)
{
    pr_info("register empty syscall\n");
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
