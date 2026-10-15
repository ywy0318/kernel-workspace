#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/memblock.h>
#include <linux/init.h>

static int __init memblock_demo_init(void)
{
    struct memblock_region *reg;
    pr_info("demo32: memblock memory regions:\n");
    for_each_mem_region(reg) {
        pr_info("  phys: %pa ~ %pa\n", &reg->base, &reg->end);
    }
    return 0;
}

static void __exit memblock_demo_exit(void)
{
    pr_info("demo32: module unload\n");
}

module_init(memblock_demo_init);
module_exit(memblock_demo_exit);
MODULE_LICENSE("GPL");
