// SPDX-License-Identifier: GPL-2.0
/* shadow_dev.c — символьное устройство /dev/shadow0 (ЭТАЛОН, s06e12).
 *
 * Финал сезона: измерения, лежащие в буфере ядра, становятся доступны
 * обычными open/read/close. Вся арифметика — в проверенных
 * shadow_ring.c и shadow_view.c; здесь только граница с ядром и с
 * пользовательским пространством.
 */

#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/mutex.h>
#include <linux/slab.h>
#include <linux/uaccess.h>

#include "shadow_ring.h"
#include "shadow_view.h"

#define SHADOW_NAME       "shadow"
#define SHADOW_DEPTH_MIN  4
#define SHADOW_DEPTH_MAX  SHADOW_RING_MAX
#define SHADOW_TEXT_MAX   (SHADOW_RING_MAX * 32)

static int depth = 16;
module_param(depth, int, 0444);
MODULE_PARM_DESC(depth, "глубина кольцевого буфера измерений (4..64)");

static struct shadow_ring *ring;
static char *text;                 /* снимок буфера в виде текста */
static DEFINE_MUTEX(shadow_lock);  /* читателей может быть несколько */

static dev_t          shadow_devt;
static struct cdev    shadow_cdev;
static struct class  *shadow_class;

/* ── операции над файлом ──────────────────────────────────────────── */

static int shadow_open(struct inode *inode, struct file *file)
{
	pr_info("shadow: открыт\n");
	return 0;
}

static int shadow_release(struct inode *inode, struct file *file)
{
	pr_info("shadow: закрыт\n");
	return 0;
}

static ssize_t shadow_read(struct file *file, char __user *ubuf,
			   size_t count, loff_t *ppos)
{
	int len, n;
	char *chunk;

	if (mutex_lock_interruptible(&shadow_lock))
		return -ERESTARTSYS;

	/* Снимок готовим один раз на позиции 0: иначе при чтении по кускам
	 * содержимое поедет между вызовами read(). */
	len = shadow_render(ring, text, SHADOW_TEXT_MAX);
	if (len < 0) {
		mutex_unlock(&shadow_lock);
		return -EIO;
	}

	chunk = kmalloc(count ? count : 1, GFP_KERNEL);
	if (!chunk) {
		mutex_unlock(&shadow_lock);
		return -ENOMEM;
	}

	/* Сколько отдать — считает проверенная функция, а не драйвер. */
	n = shadow_copy_slice(text, (size_t)len, (size_t)*ppos, chunk, count);
	if (n < 0) {
		kfree(chunk);
		mutex_unlock(&shadow_lock);
		return -EINVAL;
	}
	if (n == 0) {                     /* конец данных */
		kfree(chunk);
		mutex_unlock(&shadow_lock);
		return 0;
	}

	/* Указатель ubuf принадлежит пользовательскому процессу. Писать по
	 * нему напрямую нельзя: страница может быть не отображена, адрес
	 * может быть чужим или намеренно поддельным. copy_to_user делает
	 * это безопасно и возвращает число НЕскопированных байт. */
	if (copy_to_user(ubuf, chunk, (size_t)n)) {
		kfree(chunk);
		mutex_unlock(&shadow_lock);
		return -EFAULT;
	}

	*ppos += n;
	kfree(chunk);
	mutex_unlock(&shadow_lock);
	return n;
}

static const struct file_operations shadow_fops = {
	.owner   = THIS_MODULE,     /* модуль не выгрузится, пока файл открыт */
	.open    = shadow_open,
	.read    = shadow_read,
	.release = shadow_release,
	.llseek  = default_llseek,
};

/* ── загрузка и выгрузка ──────────────────────────────────────────── */

static int __init shadow_dev_init(void)
{
	int err, effective;
	struct device *dev;
	unsigned int i;

	effective = shadow_param_clamp(depth, SHADOW_DEPTH_MIN, SHADOW_DEPTH_MAX);
	if (effective != depth)
		pr_warn("shadow: depth=%d вне [%d, %d], беру %d\n",
			depth, SHADOW_DEPTH_MIN, SHADOW_DEPTH_MAX, effective);

	ring = kzalloc(sizeof(*ring), GFP_KERNEL);
	if (!ring)
		return -ENOMEM;
	shadow_ring_init(ring, (unsigned int)effective);

	/* немного данных, чтобы устройство было что читать */
	for (i = 0; i < (unsigned int)effective; i++)
		shadow_ring_push(ring, 22000 + (int)i * 137);

	text = kzalloc(SHADOW_TEXT_MAX, GFP_KERNEL);
	if (!text) {
		err = -ENOMEM;
		goto err_ring;
	}

	err = alloc_chrdev_region(&shadow_devt, 0, 1, SHADOW_NAME);
	if (err)
		goto err_text;

	cdev_init(&shadow_cdev, &shadow_fops);
	shadow_cdev.owner = THIS_MODULE;
	err = cdev_add(&shadow_cdev, shadow_devt, 1);
	if (err)
		goto err_region;

	shadow_class = class_create(SHADOW_NAME);
	if (IS_ERR(shadow_class)) {
		err = PTR_ERR(shadow_class);
		goto err_cdev;
	}

	dev = device_create(shadow_class, NULL, shadow_devt, NULL, "shadow0");
	if (IS_ERR(dev)) {
		err = PTR_ERR(dev);
		goto err_class;
	}

	pr_info("shadow: /dev/shadow0 готов, major=%d minor=%d, глубина %d\n",
		MAJOR(shadow_devt), MINOR(shadow_devt), effective);
	return 0;

/* Лестница отката: каждая метка освобождает ровно то, что успели взять
 * ДО неё. Порядок обратный порядку захвата. */
err_class:
	class_destroy(shadow_class);
err_cdev:
	cdev_del(&shadow_cdev);
err_region:
	unregister_chrdev_region(shadow_devt, 1);
err_text:
	kfree(text);
	text = NULL;
err_ring:
	kfree(ring);
	ring = NULL;
	return err;
}

static void __exit shadow_dev_exit(void)
{
	device_destroy(shadow_class, shadow_devt);
	class_destroy(shadow_class);
	cdev_del(&shadow_cdev);
	unregister_chrdev_region(shadow_devt, 1);
	kfree(text);
	kfree(ring);
	pr_info("shadow: выгружен\n");
}

module_init(shadow_dev_init);
module_exit(shadow_dev_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("shadow_mesh");
MODULE_DESCRIPTION("символьное устройство узла shadow_mesh");
MODULE_VERSION("1.0");
