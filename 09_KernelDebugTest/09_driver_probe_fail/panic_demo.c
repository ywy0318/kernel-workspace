#include <linux/module.h>
#include <linux/platform_device.h>

static int demo_probe(struct platform_device *pdev)
{
    pr_info("probe function return error\n");
    return -ENODEV;
}

// 重点修改：返回值从 int → void
static void demo_remove(struct platform_device *pdev)
{
    pr_info("demo remove called\n");
}

static struct platform_driver demo_drv = {
    .probe = demo_probe,
    .remove = demo_remove,
    .driver = {
        .name = "demo_probe_fail",
    },
};

static int __init demo_init(void)
{
    pr_info("register platform driver\n");
    return platform_driver_register(&demo_drv);
}

static void __exit demo_exit(void)
{
    platform_driver_unregister(&demo_drv);
    pr_info("module exit\n");
}

module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");

