# Solution — Episode 24: Kernel Modules & Device Drivers

Production-ready kernel modules.

## Содержимое

- `modules/hello_complete.ko` — Complete hello module
- `modules/char_driver.ko` — Character device driver
- `scripts/load_module.sh` — Auto-load script

## Использование

```bash
# Build all modules
cd modules/
make

# Load module
sudo insmod hello_complete.ko

# Verify
lsmod | grep hello
dmesg | tail

# Unload
sudo rmmod hello_complete
```
