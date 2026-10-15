#include <linux/module.h>
#include <linux/platform_device.h>

static int demo_probe(struct platform_device *pdev)
{
    pr_info("probe function return error\n");
    return -ENODEV; //probe返回失败
}
static int demo_remove(struct platform_device *pdev)
{
    return 0;
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
    return platform_driver_register(&demo_drv);
}

static void __exit demo_exit(void)
{
    platform_driver_unregister(&demo_drv);
}
module_init(demo_init);
module_exit(demo_exit);
MODULE_LICENSE("GPL");
