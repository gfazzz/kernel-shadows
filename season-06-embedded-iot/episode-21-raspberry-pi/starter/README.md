# Starter Files — Episode 21: Raspberry Pi & GPIO

## 📁 Содержимое

Эта директория содержит **starter templates** для выполнения задания Episode 21.

**Файлы:**
- `c-code/gpio_control.c` — GPIO control skeleton (ваша задача!)
- `c-code/Makefile` — compilation makefile
- `configs/pi_setup.sh` — Raspberry Pi initial setup script
- `camera_stream.sh` — Camera streaming starter

## 🚀 Как использовать

### 1. GPIO Control Program

**Задача:** Завершить `gpio_control.c` для управления LED через GPIO.

```bash
cd c-code/

# Ваш код здесь (TODOs в файле)
nano gpio_control.c

# Compile
make

# Run
sudo ./gpio_control
```

**Требования:**
- Использовать libgpiod library
- LED blink 5 раз
- Cleanup GPIO после использования

### 2. Pi Setup

```bash
# Initial setup
bash configs/pi_setup.sh

# Follow prompts
```

### 3. Camera Stream

```bash
# Complete camera_stream.sh
nano camera_stream.sh

# Test
bash camera_stream.sh
```

---

## 📝 GPIO Programming Tips

**libgpiod API:**
```c
#include <gpiod.h>

// Open chip
struct gpiod_chip *chip = gpiod_chip_open_by_name("gpiochip0");

// Get line
struct gpiod_line *line = gpiod_chip_get_line(chip, GPIO_NUM);

// Request output
gpiod_line_request_output(line, "program_name", 0);

// Set value
gpiod_line_set_value(line, 1);  // HIGH
gpiod_line_set_value(line, 0);  // LOW

// Cleanup
gpiod_line_release(line);
gpiod_chip_close(chip);
```

---

> **Li Wei:** *"GPIO programming — это первый шаг к hardware control. Один неправильный вольтаж — fried Pi. Читай datasheet. Всегда."*
