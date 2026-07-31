/*
 * hello_kernel.c - Простейший kernel module
 * Episode 24: Kernel Modules & Device Drivers
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("KERNEL SHADOWS");
MODULE_DESCRIPTION("Hello Kernel Module - Episode 24");
MODULE_VERSION("1.0");

static int __init hello_init(void)
{
    printk(KERN_INFO "Hello, Kernel! Module loaded\n");
    return 0;
}

static void __exit hello_exit(void)
{
    printk(KERN_INFO "Goodbye, Kernel! Module unloaded\n");
}

module_init(hello_init);
module_exit(hello_exit);
