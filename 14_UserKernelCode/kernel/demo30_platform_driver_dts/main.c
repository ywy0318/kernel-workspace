#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/init.h>

static int demo_probe(struct platform_device *pdev)
{
	pr_info("demo30: platform driver probe, matched with dts\n");
	return 0;
}

static void demo_remove(struct platform_device *pdev)
{
	pr_info("demo30: platform driver remove\n");
}

static const struct of_device_id demo_of_match[] = {
	{ .compatible = "demo,platform-demo30" },
	{}
};
MODULE_DEVICE_TABLE(of, demo_of_match);

static struct platform_driver demo_platform_drv = {
	.probe = demo_probe,
	.remove = demo_remove,
	.driver = {
		.name = "demo30_platform",
		.of_match_table = demo_of_match,
	},
};

static int __init plat_drv_init(void)
{
	return platform_driver_register(&demo_platform_drv);
}

static void __exit plat_drv_exit(void)
{
	platform_driver_unregister(&demo_platform_drv);
}

module_init(plat_drv_init);
module_exit(plat_drv_exit);
MODULE_LICENSE("GPL");



