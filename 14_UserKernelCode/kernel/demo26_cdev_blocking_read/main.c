#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/wait.h>
#include <linux/init.h>

static dev_t devno;
static struct cdev cdev;
static struct class *cls;
static wait_queue_head_t wq;
static int has_data = 0;
static char kbuf[128];

static int dev_open(struct inode *inode, struct file *file)
{
	pr_info("demo26 open\n");
	return 0;
}

static int dev_release(struct inode *inode, struct file *file)
{
	pr_info("demo26 release\n");
	return 0;
}

static ssize_t dev_read(struct file *file, char __user *buf, size_t count, loff_t *ppos)
{
	int ret;
	ret = wait_event_interruptible(wq, has_data);
	if (ret)
		return ret;

	size_t copy_len = min(count, (size_t)sizeof(kbuf));
	if(copy_to_user(buf, kbuf, copy_len))
		return -EFAULT;

	has_data = 0;
	pr_info("demo26 read consume data, len=%zu\n", copy_len);
	return copy_len;
}

static ssize_t dev_write(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
	size_t copy_len = min(count, (size_t)sizeof(kbuf)-1);
	if(copy_from_user(kbuf, buf, copy_len))
		return -EFAULT;

	kbuf[copy_len] = '\0';
	has_data = 1;
	wake_up(&wq);
	pr_info("demo26 write produce data: %s\n", kbuf);
	return copy_len;
}

static const struct file_operations fops = {
	.owner = THIS_MODULE,
	.open = dev_open,
	.release = dev_release,
	.read = dev_read,
	.write = dev_write,
};

static int __init cdev_block_init(void)
{
	int ret;
	init_waitqueue_head(&wq);
	ret = alloc_chrdev_region(&devno,0,1,"demo26");
	if(ret) return ret;

	cdev_init(&cdev, &fops);
	cdev_add(&cdev, devno, 1);

	cls = class_create("demo26_class");
	if (IS_ERR(cls)) {
		ret = PTR_ERR(cls);
		cdev_del(&cdev);
		unregister_chrdev_region(devno,1);
		return ret;
	}

	device_create(cls, NULL, devno, NULL, "demo26_dev");
	pr_info("demo26 blocking cdev /dev/demo26_dev\n");
	return 0;
}

static void __exit cdev_block_exit(void)
{
	device_destroy(cls, devno);
	class_destroy(cls);
	cdev_del(&cdev);
	unregister_chrdev_region(devno,1);
	pr_info("demo26 exit\n");
}

module_init(cdev_block_init);
module_exit(cdev_block_exit);
MODULE_LICENSE("GPL");


