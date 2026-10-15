#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/uaccess.h>

static int __init demo_init(void)
{
    char __user *user_ptr = (char __user *)0x10000;
    char buf[16];
    pr_info("kernel try access user ptr directly\n");
    // 非法直接解引用用户指针，不使用copy_from_user
    *user_ptr = 'A';
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
