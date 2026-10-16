#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/gfp.h>
#include <linux/mm.h>
#include <linux/init.h>
#include <linux/page-flags.h>

static int __init traverse_page_init(void)
{
	unsigned long pfn;
	int printed = 0;
	const int MAX_PRINT = 20;

	pr_info("demo33: traverse page demo start\n");

	// 从 0x10000（65536）开始扫描，QEMU arm64内存一般放在高PFN
	for (pfn = 65536; pfn < 131072; pfn++) {
		struct page *page;

		if (printed >= MAX_PRINT)
			break;

		if (!pfn_valid(pfn))
			continue;

		page = pfn_to_page(pfn);

		pr_info("demo33: pfn:%lu phys:%#llx page:%p refcnt:%d "
			"Reserved:%d Locked:%d Dirty:%d Uptodate:%d "
			"Anon:%d Huge:%d Slab:%d\n",
			pfn,
			(u64)pfn << PAGE_SHIFT,
			page,
			page_count(page),
			PageReserved(page),
			PageLocked(page),
			PageDirty(page),
			PageUptodate(page),
			PageAnon(page),
			PageHuge(page),
			PageSlab(page));

		printed++;
	}

	pr_info("demo33: traverse done, total printed:%d\n", printed);
	return 0;
}

static void __exit traverse_page_exit(void)
{
	pr_info("demo33: module unload\n");
}

module_init(traverse_page_init);
module_exit(traverse_page_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo33 simple scan pfn struct page");








