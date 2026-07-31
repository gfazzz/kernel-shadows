/*
 * char_device.c - Character Device Driver
 * Episode 24: Kernel Modules & Device Drivers
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>

#define DEVICE_NAME "mychardev"
#define CLASS_NAME "mychar"
#define BUF_SIZE 1024

MODULE_LICENSE("GPL");
MODULE_AUTHOR("KERNEL SHADOWS");

static int major_number;
static char device_buffer[BUF_SIZE];
static int buffer_size = 0;
static struct class *char_class = NULL;
static struct device *char_device = NULL;

static int dev_open(struct inode *, struct file *);
static int dev_release(struct inode *, struct file *);
static ssize_t dev_read(struct file *, char __user *, size_t, loff_t *);
static ssize_t dev_write(struct file *, const char __user *, size_t, loff_t *);

static struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = dev_open,
    .release = dev_release,
    .read = dev_read,
    .write = dev_write,
};

static int __init char_device_init(void)
{
    major_number = register_chrdev(0, DEVICE_NAME, &fops);
    if (major_number < 0) {
        printk(KERN_ALERT "Failed to register character device\n");
        return major_number;
    }
    
    char_class = class_create(THIS_MODULE, CLASS_NAME);
    char_device = device_create(char_class, NULL, MKDEV(major_number, 0), NULL, DEVICE_NAME);
    
    printk(KERN_INFO "Character device registered: major=%d\n", major_number);
    return 0;
}

static void __exit char_device_exit(void)
{
    device_destroy(char_class, MKDEV(major_number, 0));
    class_destroy(char_class);
    unregister_chrdev(major_number, DEVICE_NAME);
    printk(KERN_INFO "Character device unregistered\n");
}

static int dev_open(struct inode *inodep, struct file *filep)
{
    printk(KERN_INFO "Device opened\n");
    return 0;
}

static int dev_release(struct inode *inodep, struct file *filep)
{
    printk(KERN_INFO "Device closed\n");
    return 0;
}

static ssize_t dev_read(struct file *filep, char __user *buffer, size_t len, loff_t *offset)
{
    int bytes_read = 0;
    
    if (*offset >= buffer_size)
        return 0;
    
    if (*offset + len > buffer_size)
        len = buffer_size - *offset;
    
    if (copy_to_user(buffer, device_buffer + *offset, len))
        return -EFAULT;
    
    *offset += len;
    bytes_read = len;
    
    printk(KERN_INFO "Read %d bytes\n", bytes_read);
    return bytes_read;
}

static ssize_t dev_write(struct file *filep, const char __user *buffer, size_t len, loff_t *offset)
{
    if (len > BUF_SIZE)
        len = BUF_SIZE;
    
    if (copy_from_user(device_buffer, buffer, len))
        return -EFAULT;
    
    buffer_size = len;
    printk(KERN_INFO "Wrote %zu bytes\n", len);
    return len;
}

module_init(char_device_init);
module_exit(char_device_exit);
