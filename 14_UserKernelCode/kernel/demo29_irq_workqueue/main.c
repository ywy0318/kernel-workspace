#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/workqueue.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/init.h>

static struct work_struct work;
static dev_t devno;
static struct cdev cdev;
static struct class *cls;

static void work_handler(struct work_struct *w)
{
	pr_info("demo29 workqueue as irq bottom half\n");
}

static irqreturn_t fake_irq_handler(int irq, void *arg)
{
	pr_info("demo29 fake irq top half\n");
	schedule_work(&work);
	return IRQ_HANDLED;
}

static ssize_t dev_write(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
	pr_info("user trigger fake irq\n");
	fake_irq_handler(0, NULL); // 模拟硬件中断触发
	return count;
}

static const struct file_operations fops = {
	.owner = THIS_MODULE,
	.write = dev_write,
};

static int __init irq_work_init(void)
{
	int ret;
	INIT_WORK(&work, work_handler);

	ret = alloc_chrdev_region(&devno, 0, 1, "demo29");
	if(ret) return ret;
	cdev_init(&cdev, &fops);
	cdev_add(&cdev, devno, 1);

	cls = class_create("demo29_class");
	if (IS_ERR(cls)) {
		ret = PTR_ERR(cls);
		cdev_del(&cdev);
		unregister_chrdev_region(devno, 1);
		return ret;
	}
	device_create(cls, NULL, devno, NULL, "demo29_dev");

	pr_info("demo29 irq+workqueue demo loaded\n");
	return 0;
}

static void __exit irq_work_exit(void)
{
	// 卸载前等待work执行完毕，防止模块卸载时work还在运行
	flush_work(&work);

	device_destroy(cls, devno);
	class_destroy(cls);
	cdev_del(&cdev);
	unregister_chrdev_region(devno,1);
	pr_info("demo29 exit\n");
}

module_init(irq_work_init);
module_exit(irq_work_exit);
MODULE_LICENSE("GPL");

