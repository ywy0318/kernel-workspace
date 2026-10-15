#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/init.h>

#define BUF_SZ 128
static dev_t devno;
static struct cdev cdev;
static struct class *cls;
static char kbuf[BUF_SZ];

static int dev_open(struct inode *inode, struct file *file)
{
    pr_info("demo25 open\n");
    return 0;
}
static int dev_release(struct inode *inode, struct file *file)
{
    pr_info("demo25 release\n");
    return 0;
}
static ssize_t dev_read(struct file *file, char __user *buf, size_t count, loff_t *ppos)
{
    if(*ppos >= BUF_SZ) return 0;
    count = min(count, (size_t)(BUF_SZ - *ppos));
    if(copy_to_user(buf, kbuf + *ppos, count))
        return -EFAULT;
    *ppos += count;
    return count;
}
static ssize_t dev_write(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
    if(*ppos >= BUF_SZ) return -ENOSPC;
    count = min(count, (size_t)(BUF_SZ - *ppos));
    if(copy_from_user(kbuf + *ppos, buf, count))
        return -EFAULT;
    *ppos += count;
    pr_info("demo25 write %zu bytes\n",count);
    return count;
}
static const struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = dev_open,
    .release = dev_release,
    .read = dev_read,
    .write = dev_write,
};

static int __init cdev_rw_init(void)
{
    int ret;
    ret = alloc_chrdev_region(&devno,0,1,"demo25");
    if(ret) return ret;
    cdev_init(&cdev, &fops);
    cdev_add(&cdev, devno, 1);
    cls = class_create(THIS_MODULE, "demo25_class");
    device_create(cls, NULL, devno, NULL, "demo25_dev");
    pr_info("demo25 cdev rw /dev/demo25_dev\n");
    return 0;
}

static void __exit cdev_rw_exit(void)
{
    device_destroy(cls, devno);
    class_destroy(cls);
    cdev_del(&cdev);
    unregister_chrdev_region(devno,1);
    pr_info("demo25 exit\n");
}

module_init(cdev_rw_init);
module_exit(cdev_rw_exit);
MODULE_LICENSE("GPL");
