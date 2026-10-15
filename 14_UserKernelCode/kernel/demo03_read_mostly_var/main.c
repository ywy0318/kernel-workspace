#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int __read_mostly g_ro_var = 1234;

static int __init readmostly_init(void)
{
    pr_info("demo03: __read_mostly var = %d\n", g_ro_var);
    return 0;
}

static void __exit readmostly_exit(void)
{
    pr_info("demo03 unload\n");
}

module_init(readmostly_init);
module_exit(readmostly_exit);
MODULE_LICENSE("GPL");
