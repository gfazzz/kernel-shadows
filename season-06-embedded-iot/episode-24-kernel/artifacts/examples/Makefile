# Makefile for Kernel Modules - Episode 24

obj-m += hello_kernel.o
obj-m += char_device.o
obj-m += gpio_driver.o

# Kernel build directory
KDIR := /lib/modules/$(shell uname -r)/build

# Current directory
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install

load:
	sudo insmod hello_kernel.ko

unload:
	sudo rmmod hello_kernel

test:
	dmesg | tail -10

.PHONY: all clean install load unload test
