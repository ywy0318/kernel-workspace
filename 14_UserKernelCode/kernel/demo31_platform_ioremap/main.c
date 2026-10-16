#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/of_address.h>
#include <linux/io.h>
#include <linux/init.h>

static void __iomem *io_base;

static int demo_probe(struct platform_device *pdev)
{
	struct resource res;
	if (of_address_to_resource(pdev->dev.of_node, 0, &res)) {
		pr_err("demo31: get resource failed\n");
		return -ENODEV;
	}
	io_base = devm_ioremap_resource(&pdev->dev, &res);
	if (IS_ERR(io_base)) {
		pr_err("demo31: ioremap failed\n");
		return PTR_ERR(io_base);
	}
	pr_info("demo31: phys:%pa, virt:%p\n", &res.start, io_base);
	return 0;
}

static void demo_remove(struct platform_device *pdev)
{
	pr_info("demo31: platform driver remove\n");
}

static const struct of_device_id demo_of_match[] = {
	{ .compatible = "demo,platform-demo31" },
	{}
};
MODULE_DEVICE_TABLE(of, demo_of_match);

static struct platform_driver demo_platform_drv = {
	.probe = demo_probe,
	.remove = demo_remove,
	.driver = {
		.name = "demo31_platform_ioremap",
		.of_match_table = demo_of_match,
	},
};

static int __init plat_ioremap_init(void)
{
	return platform_driver_register(&demo_platform_drv);
}

static void __exit plat_ioremap_exit(void)
{
	platform_driver_unregister(&demo_platform_drv);
}

module_init(plat_ioremap_init);
module_exit(plat_ioremap_exit);
MODULE_LICENSE("GPL");

