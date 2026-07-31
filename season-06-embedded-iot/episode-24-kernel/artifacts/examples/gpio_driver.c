/*
 * gpio_driver.c - GPIO Device Driver (Raspberry Pi)
 * Episode 24: Kernel Modules & Device Drivers
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/gpio.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("KERNEL SHADOWS");

#define GPIO_PIN 17

static int __init gpio_driver_init(void)
{
    int ret;
    
    ret = gpio_request(GPIO_PIN, "gpio_driver");
    if (ret) {
        printk(KERN_ALERT "GPIO request failed\n");
        return ret;
    }
    
    gpio_direction_output(GPIO_PIN, 0);
    gpio_set_value(GPIO_PIN, 1);
    
    printk(KERN_INFO "GPIO driver loaded, pin %d HIGH\n", GPIO_PIN);
    return 0;
}

static void __exit gpio_driver_exit(void)
{
    gpio_set_value(GPIO_PIN, 0);
    gpio_free(GPIO_PIN);
    printk(KERN_INFO "GPIO driver unloaded\n");
}

module_init(gpio_driver_init);
module_exit(gpio_driver_exit);
