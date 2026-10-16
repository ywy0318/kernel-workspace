#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/gfp.h>
#include <linux/init.h>
#include <linux/mm.h>   // 新增！page_address / struct page 相关

static struct page *p;

static int __init page_demo_init(void)
{
	p = alloc_page(GFP_KERNEL);
	if (!p)
		return -ENOMEM;
	// %pK 打印内核虚拟地址
	pr_info("demo10 alloc page: page=%pK, virtual=%pK\n", p, page_address(p));
	return 0;
}

static void __exit page_demo_exit(void)
{
	__free_page(p);
	pr_info("demo10 free page done\n");
}

module_init(page_demo_init);
module_exit(page_demo_exit);
MODULE_LICENSE("GPL");

