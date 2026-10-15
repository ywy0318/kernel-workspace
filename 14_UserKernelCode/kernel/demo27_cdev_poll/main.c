#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/wait.h>
#include <linux/poll.h>
#include <linux/init.h>

static dev_t devno;
static struct cdev cdev;
static struct class *cls;
static wait_queue_head_t wq;
static int has_data = 0;
static char kbuf[128];

static int dev_open(struct inode *inode, struct file *file)
{
    pr_info("demo27 open\n");
    return 0;
}
static int dev_release(struct inode *inode, struct file *file)
{
    pr_info("demo27 release\n");
    return 0;
}
static ssize_t dev_read(struct file *file, char __user *buf, size_t count, loff_t *ppos)
{
    if(copy_to_user(buf, kbuf, count))
        return -EFAULT;
    has_data = 0;
    pr_info("demo27 read consume\n");
    return count;
}
static ssize_t dev_write(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
    if(copy_from_user(kbuf, buf, count))
        return -EFAULT;
    has_data = 1;
    wake_up(&wq);
    pr_info("demo27 write produce\n");
    return count;
}
static __poll_t dev_poll(struct file *file, poll_table *wait)
{
    __poll_t mask = 0;
    poll_wait(file, &wq, wait);
    if (has_data)
        mask |= POLLIN;
    return mask;
}
static const struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = dev_open,
    .release = dev_release,
    .read = dev_read,
    .write = dev_write,
    .poll = dev_poll,
};

static int __init cdev_poll_init(void)
{
    int ret;
    init_waitqueue_head(&wq);
    ret = alloc_chrdev_region(&devno,0,1,"demo27");
    if(ret) return ret;
    cdev_init(&cdev, &fops);
    cdev_add(&cdev, devno, 1);
    cls = class_create(THIS_MODULE, "demo27_class");
    device_create(cls, NULL, devno, NULL, "demo27_dev");
    pr_info("demo27 cdev poll /dev/demo27_dev\n");
    return 0;
}

static void __exit cdev_poll_exit(void)
{
    device_destroy(cls, devno);
    class_destroy(cls);
    cdev_del(&cdev);
    unregister_chrdev_region(devno,1);
    pr_info("demo27 exit\n");
}

module_init(cdev_poll_init);
module_exit(cdev_poll_exit);
MODULE_LICENSE("GPL");
