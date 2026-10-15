#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int __init simple_mod_init(void)
{
    pr_info("demo01: simple module loaded\n");
    return 0;
}

static void __exit simple_mod_exit(void)
{
    pr_info("demo01: simple module unloaded\n");
}

module_init(simple_mod_init);
module_exit(simple_mod_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("demo01 simple module");
MODULE_AUTHOR("ywy");
