/*
 * hello_module.c - Starter Kernel Module
 * Episode 24: Complete the TODOs
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Student");
MODULE_DESCRIPTION("Hello Module - Episode 24");

static int __init hello_init(void)
{
    // TODO 1: Print "Hello from kernel!" using printk
    // TODO 2: Return 0 on success
    return 0;
}

static void __exit hello_exit(void)
{
    // TODO 3: Print "Goodbye from kernel!" using printk
}

// TODO 4: Register init and exit functions
// module_init(?);
// module_exit(?);
