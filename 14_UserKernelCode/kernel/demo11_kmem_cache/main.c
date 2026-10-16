#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/init.h>

struct my_obj {
	int a;
	char buf[32];
};
static struct kmem_cache *cache;
static struct my_obj *obj;

static int __init slab_init(void)
{
	// 重点：增加 SLAB_ACCOUNT
	cache = kmem_cache_create("demo11_cache", sizeof(struct my_obj), 0, SLAB_ACCOUNT, NULL);
	if (!cache) {
		pr_err("demo11 kmem_cache_create failed!\n");
		return -ENOMEM;
	}
	pr_info("demo11 cache create ok\n");

	obj = kmem_cache_alloc(cache, GFP_KERNEL);
	if (!obj) {
		pr_err("demo11 kmem_cache_alloc fail\n");
		kmem_cache_destroy(cache);
		return -ENOMEM;
	}
	obj->a = 1000;
	pr_info("demo11 slab alloc obj->a=%d\n", obj->a);
	return 0;
}

static void __exit slab_exit(void)
{
	if (obj) {
		kmem_cache_free(cache, obj);
	}
	if (cache) {
		kmem_cache_destroy(cache);
	}
	pr_info("demo11 slab destroy done\n");
}

module_init(slab_init);
module_exit(slab_exit);
MODULE_LICENSE("GPL");
