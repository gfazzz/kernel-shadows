# Episode 24: Artifacts — Kernel Modules & Device Drivers

## 📦 Содержимое

Примеры kernel modules и device drivers для Linux.

## 📁 Директории

### 1. examples/

**hello_kernel.c** — Простейший kernel module (Hello World)
**char_device.c** — Character device driver пример
**gpio_driver.c** — GPIO device driver для Raspberry Pi
**Makefile** — Build system для kernel modules

### 2. configs/

**module.conf** — Конфигурация для auto-load модулей

### 3. docs/

**kernel_apis.md** — Документация kernel APIs
**device_tree.md** — Device Tree basics

---

## 🎯 Использование

### Build kernel module

```bash
# Установить kernel headers
sudo apt install -y linux-headers-$(uname -r)

# Build module
cd examples/
make

# Load module
sudo insmod hello_kernel.ko

# Check dmesg
dmesg | tail

# Unload module
sudo rmmod hello_kernel
```

### Character Device

```bash
# Build and load
make
sudo insmod char_device.ko

# Check device created
ls -l /dev/mychardev

# Test read/write
echo "Hello" | sudo tee /dev/mychardev
sudo cat /dev/mychardev

# Unload
sudo rmmod char_device
```

---

> **Li Wei:** *"Kernel space — это где user space заканчивается. Здесь нет printf, нет stdlib, нет прощения. Один segfault — kernel panic, вся система падает. Welcome to the deep end."*
