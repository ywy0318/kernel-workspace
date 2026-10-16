#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/ioport.h>

static void walk_resource(struct resource *res, int depth)
{
	struct resource *child;
	if (!res)
		return;

	// 打印当前资源区间
	pr_info("%*s %pa ~ %pa : %s\n", depth*2, "", &res->start, &res->end, res->name ? res->name : "(unnamed)");

	// 递归遍历子资源
	for (child = res->child; child; child = child->sibling) {
		walk_resource(child, depth + 1);
	}
}

static int __init mem_demo_init(void)
{
	pr_info("demo32: dump iomem resource tree (/proc/iomem)\n");
	walk_resource(&iomem_resource, 0);
	return 0;
}

static void __exit mem_demo_exit(void)
{
	pr_info("demo32: module unload\n");
}

module_init(mem_demo_init);
module_exit(mem_demo_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo32 dump iomem resource");






