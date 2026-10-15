#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/init.h>
#include <linux/uaccess.h>

static struct proc_dir_entry *proc_entry;
static int proc_val = 999;

static ssize_t proc_read(struct file *file, char __user *buf, size_t count, loff_t *ppos)
{
    char tmp[64];
    int len;
    if (*ppos > 0)
        return 0;
    len = snprintf(tmp, sizeof(tmp), "%d\n", proc_val);
    if (copy_to_user(buf, tmp, len))
        return -EFAULT;
    *ppos = len;
    return len;
}

static const struct proc_ops proc_fops = {
    .proc_read = proc_read,
};

static int __init proc_ro_init(void)
{
    proc_entry = proc_create("demo04_ro", 0444, NULL, &proc_fops);
    if (!proc_entry)
        return -ENOMEM;
    pr_info("demo04 proc ro created\n");
    return 0;
}

static void __exit proc_ro_exit(void)
{
    proc_remove(proc_entry);
    pr_info("demo04 proc removed\n");
}

module_init(proc_ro_init);
module_exit(proc_ro_exit);
MODULE_LICENSE("GPL");
