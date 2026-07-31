# Episode 21: Artifacts — Raspberry Pi & GPIO

## 📦 Содержимое

Эта директория содержит **конфигурационные файлы** и **примеры** для Raspberry Pi setup.

## 📁 Директории

### 1. configs/

Production-ready configurations для Raspberry Pi:

**config.txt** — Boot configuration (GPU memory, camera enable, GPIO)
**cmdline.txt** — Kernel boot parameters
**ssh_config** — Hardened SSH для remote access

### 2. examples/

Example code и scripts:

**gpio_blink.c** — Simple GPIO LED blink (learning example)
**camera_test.sh** — Camera verification script
**gpio_pinout.txt** — RPi GPIO pin reference

---

## 🎯 Использование

### Шаг 1: Raspberry Pi Setup

```bash
# Flash Ubuntu to SD card
# https://ubuntu.com/download/raspberry-pi

# Boot Pi, SSH access
ssh ubuntu@raspberrypi.local
# Default password: ubuntu (change immediately!)
```

### Шаг 2: Apply Configs

```bash
# Copy boot config
sudo cp configs/config.txt /boot/firmware/config.txt

# Enable camera
sudo raspi-config
# Interface Options → Camera → Enable

# Reboot
sudo reboot
```

### Шаг 3: Test GPIO

```bash
# Install GPIO tools
sudo apt update
sudo apt install gpiod libgpiod-dev

# Test with example
gcc examples/gpio_blink.c -o blink -lgpiod
sudo ./blink
```

### Шаг 4: Camera Test

```bash
# Test camera
bash examples/camera_test.sh

# Should output: Camera detected
```

---

## 📝 GPIO Pin Reference

See `examples/gpio_pinout.txt` for complete pinout.

**Quick reference:**
- GPIO 2, 3: I2C (SDA, SCL)
- GPIO 14, 15: UART (TXD, RXD)
- GPIO 17, 27, 22: General purpose (LEDs, buttons)
- Pin 1, 17: 3.3V power
- Pin 2, 4: 5V power
- Pin 6, 9, 14, 20, 25, 30, 34, 39: Ground

---

> **Li Wei:** *"Raspberry Pi — это полноценный Linux computer размером с кредитку. И GPIO pins — это твой интерфейс к физическому миру."*
