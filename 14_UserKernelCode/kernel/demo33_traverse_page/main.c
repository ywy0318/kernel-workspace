#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/gfp.h>
#include <linux/mm.h>
#include <linux/init.h>
#include <linux/page-flags.h>
#include <linux/nodemask.h>  // for_each_online_node

static int __init demo33_traverse_page_init(void)
{
	int nid;
	struct zone *zone;
	unsigned long pfn;
	int printed = 0;
	const int MAX_PRINT = 20;

	pr_info("demo33: start traverse all system struct page\n");

	// 遍历所有在线NUMA节点（QEMU arm64一般只有nid=0）
	for_each_online_node(nid) {
		pg_data_t *pgdat = NODE_DATA(nid);
		if (!pgdat)
			continue;

		pr_info("demo33: === node %d ===\n", nid);
		// 遍历节点内所有zone (ZONE_DMA, ZONE_NORMAL...)
		for (zone = pgdat->node_zones; zone < pgdat->node_zones + MAX_NR_ZONES; zone++) {
			if (!zone->present_pages)
				continue;

			pr_info("demo33: zone start_pfn:%lu, zone end_pfn:%lu, present_pages:%lu\n",
				zone->zone_start_pfn, zone_end_pfn(zone), zone->present_pages);

			// 遍历zone内全部pfn
			for (pfn = zone->zone_start_pfn; pfn < zone_end_pfn(zone); pfn++) {
				if (printed >= MAX_PRINT)
					goto out_all;

				if (!pfn_valid(pfn))
					continue;

				struct page *page = pfn_to_page(pfn);
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
		}
	}
out_all:
	pr_info("demo33: traverse done, printed:%d\n", printed);
	return 0;
}

static void __exit demo33_traverse_page_exit(void)
{
	pr_info("demo33: module unload\n");
}

module_init(demo33_traverse_page_init);
module_exit(demo33_traverse_page_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo33 traverse all system struct page by node+zone");












