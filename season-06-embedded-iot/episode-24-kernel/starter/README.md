# Starter Files — Episode 24: Kernel Modules & Device Drivers

Starter templates для kernel module programming.

## Файлы

- `c-code/hello_module.c` — Простой kernel module (TODO)
- `c-code/device_driver.c` — Character device driver (TODO)
- `c-code/Makefile` — Build system

## Setup

```bash
# Install kernel headers
sudo apt install -y linux-headers-$(uname -r)

# Build module
cd c-code/
make

# Load module
sudo insmod hello_module.ko

# Check kernel log
dmesg | tail
```
