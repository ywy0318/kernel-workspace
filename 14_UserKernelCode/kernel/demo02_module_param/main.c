#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int int_val = 100;
static bool bool_val = false;
static char *str_val = "default";

module_param(int_val, int, 0644);
module_param(bool_val, bool, 0644);
module_param(str_val, charp, 0644);
MODULE_PARM_DESC(int_val, "integer parameter");
MODULE_PARM_DESC(bool_val, "bool parameter");
MODULE_PARM_DESC(str_val, "string parameter");

static int __init param_mod_init(void)
{
    pr_info("demo02: int=%d, bool=%d, str=%s\n", int_val, bool_val, str_val);
    return 0;
}

static void __exit param_mod_exit(void)
{
    pr_info("demo02: module unload\n");
}

module_init(param_mod_init);
module_exit(param_mod_exit);
MODULE_LICENSE("GPL");
