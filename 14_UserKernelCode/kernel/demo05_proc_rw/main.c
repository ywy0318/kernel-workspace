#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/init.h>
#include <linux/uaccess.h>

static struct proc_dir_entry *proc_entry;
static int proc_val = 100;

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

static ssize_t proc_write(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
    char tmp[32];
    long val;
    if (count >= sizeof(tmp))
        return -EINVAL;
    if (copy_from_user(tmp, buf, count))
        return -EFAULT;
    tmp[count] = '\0';
    if (kstrtol(tmp, 10, &val))
        return -EINVAL;
    proc_val = val;
    pr_info("demo05 write val=%ld\n", val);
    return count;
}

static const struct proc_ops proc_fops = {
    .proc_read = proc_read,
    .proc_write = proc_write,
};

static int __init proc_rw_init(void)
{
    proc_entry = proc_create("demo05_rw", 0644, NULL, &proc_fops);
    if (!proc_entry)
        return -ENOMEM;
    pr_info("demo05 proc rw created\n");
    return 0;
}

static void __exit proc_rw_exit(void)
{
    proc_remove(proc_entry);
    pr_info("demo05 proc removed\n");
}

module_init(proc_rw_init);
module_exit(proc_rw_exit);
MODULE_LICENSE("GPL");
