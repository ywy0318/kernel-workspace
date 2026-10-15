#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>

static int __init demo_init(void)
{
    pr_info("try mount invalid rootfs\n");
    // 模拟挂载不存在文件系统
    return 0;
}

static void __exit demo_exit(void)
{
    pr_info("module exit\n");
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
