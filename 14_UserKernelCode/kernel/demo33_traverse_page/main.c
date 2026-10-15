#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/gfp.h>
#include <linux/mm.h>
#include <linux/init.h>

static int __init traverse_page_init(void)
{
    unsigned long pfn;
    struct page *page;
    unsigned long count = 0;

    pr_info("demo33: traverse page demo start\n");
    for (pfn = 0; pfn < max_pfn && count < 10; pfn++) {
        page = pfn_to_page(pfn);
        if (pfn_valid(pfn)) {
            pr_info("pfn:%lu page:%p flags:0x%lx\n", pfn, page, page->flags);
            count++;
        }
    }
    pr_info("demo33: traverse done\n");
    return 0;
}

static void __exit traverse_page_exit(void)
{
    pr_info("demo33: module unload\n");
}

module_init(traverse_page_init);
module_exit(traverse_page_exit);
MODULE_LICENSE("GPL");
