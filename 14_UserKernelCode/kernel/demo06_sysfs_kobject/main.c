#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kobject.h>
#include <linux/init.h>
#include <linux/uaccess.h>

static struct kobject *demo_kobj;
static int sys_val = 500;

static ssize_t val_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    return sprintf(buf, "%d\n", sys_val);
}

static ssize_t val_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
    long v;
    if (kstrtol(buf,10,&v))
        return -EINVAL;
    sys_val = v;
    pr_info("demo06 sysfs set %ld\n",v);
    return count;
}

static struct kobj_attribute val_attr = __ATTR(val, 0644, val_show, val_store);
static struct attribute *attrs[] = {&val_attr.attr, NULL};
static struct attribute_group attr_group = {.attrs = attrs};

static int __init sysfs_init(void)
{
    int ret;
    demo_kobj = kobject_create_and_add("demo06", kernel_kobj);
    if (!demo_kobj) return -ENOMEM;
    ret = sysfs_create_group(demo_kobj, &attr_group);
    if(ret) {
        kobject_put(demo_kobj);
        return ret;
    }
    pr_info("demo06 sysfs created /sys/kernel/demo06/val\n");
    return 0;
}

static void __exit sysfs_exit(void)
{
    sysfs_remove_group(demo_kobj, &attr_group);
    kobject_put(demo_kobj);
    pr_info("demo06 sysfs removed\n");
}

module_init(sysfs_init);
module_exit(sysfs_exit);
MODULE_LICENSE("GPL");
