#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/init.h>

static dev_t devno;
static struct cdev cdev;
static struct class *cls;

static int dev_open(struct inode *inode, struct file *file)
{
	pr_info("demo24 open\n");
	return 0;
}

static int dev_release(struct inode *inode, struct file *file)
{
	pr_info("demo24 release\n");
	return 0;
}

static const struct file_operations fops = {
	.owner = THIS_MODULE,
	.open = dev_open,
	.release = dev_release,
};

static int __init cdev_simple_init(void)
{
	int ret;
	ret = alloc_chrdev_region(&devno,0,1,"demo24");
	if(ret) return ret;

	cdev_init(&cdev, &fops);
	cdev_add(&cdev, devno, 1);

	cls = class_create("demo24_class");
	if (IS_ERR(cls)) {
		ret = PTR_ERR(cls);
		cdev_del(&cdev);
		unregister_chrdev_region(devno,1);
		return ret;
	}

	device_create(cls, NULL, devno, NULL, "demo24_dev");
	pr_info("demo24 cdev created /dev/demo24_dev\n");
	return 0;
}

static void __exit cdev_simple_exit(void)
{
	device_destroy(cls, devno);
	class_destroy(cls);
	cdev_del(&cdev);
	unregister_chrdev_region(devno,1);
	pr_info("demo24 cdev removed\n");
}

module_init(cdev_simple_init);
module_exit(cdev_simple_exit);
MODULE_LICENSE("GPL");

