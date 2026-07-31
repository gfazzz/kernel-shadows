# Episode 24: Kernel Modules & Device Drivers

> *"Kernel space — это где user space заканчивается. Здесь нет printf, нет stdlib, нет прощения. Один segfault — kernel panic."* — Li Wei

```
Season 6: Embedded Linux & IoT Security
Episode 24 of 32 (SEASON FINALE!)
Локация: Шэньчжэнь 🇨🇳, Китай (Chip Fab)
Дни: 47-48 операции KERNEL SHADOWS
Длительность: 5-6 часов
Сложность: ⭐⭐⭐⭐⭐ (HARDCORE!)
Тип: Kernel Programming (Type B - C programming)
```

---

## ⚠️ ПРЕДУПРЕЖДЕНИЕ О БЕЗОПАСНОСТИ

**Разработка модулей ядра — ОПАСНА!**

### 💀 Чем опасен kernel programming

Неправильный код модуля ядра может:
- ❌ **Обрушить систему** (kernel panic)
- ❌ **Повредить данные** на диске
- ❌ **Испортить оборудование** (редко, но возможно)
- ❌ **Сделать систему незагружаемой**

**Одна ошибка = перезагрузка. Потеря несохранённых данных.**

### 🛡️ ОБЯЗАТЕЛЬНО используйте

**Вариант 1: Виртуальная машина (РЕКОМЕНДУЕТСЯ)**

```bash
# VirtualBox, VMware, или KVM
# Настройки VM:
- Оперативная память: минимум 2ГБ
- Диск: 20ГБ
- ОБЯЗАТЕЛЬНО: включите снимки (snapshots)!

# Порядок работы:
1. Написали модуль
2. Создали снимок VM
3. Загрузили модуль (insmod)
4. Система упала? Откатитесь к снимку
5. Исправили код → повторили
```

**Вариант 2: Запасной компьютер**
- Старый ноутбук или десктоп
- НЕ ваша основная рабочая машина!
- Регулярные резервные копии

**Вариант 3: Облачная VM**
- AWS EC2 (бесплатный уровень)
- DigitalOcean, Yandex Cloud
- Легко пересоздать при поломке

### ❌ НИКОГДА не делайте

**НЕ тестируйте модули ядра на:**
- ❌ Основном рабочем компьютере
- ❌ Сервере в продакшене
- ❌ Машине с важными данными без бэкапов

### ✅ Правила безопасности

1. **Всегда VM или тестовая машина**
2. **Частые снимки** (перед каждым тестом)
3. **Резервные копии** важных данных
4. **Читайте kernel log** (dmesg) внимательно
5. **Тестируйте постепенно** (маленькие изменения)

### 🎓 Вы предупреждены

**Li Wei:** *"В DJI один плохой kernel driver стоил $100,000 когда дрон упал во время демонстрации. В production это disaster. В обучении — потеря данных и времени. Используйте VM. Всегда."*

**LILITH:** *"Kernel panic — это не шутка. Видела студентов которые тестировали на основной машине. Потеряли дипломную работу. Thesis gone. Месяц работы в мусор. Всё потому что не создали бэкап. Don't be them. VM или не лезь в kernel."*

**Готовы?** Настройте VM, создайте снимок, и только тогда продолжайте.

---

## 📋 Обзор эпизода

### Что вы изучите

В этом эпизоде вы погрузитесь в **kernel space** — программирование ядра Linux:

**Технологии:**
- 🔧 **Kernel Modules** — загружаемые модули ядра
- 💾 **Character Devices** — /dev устройства
- 📡 **Device Drivers** — драйверы для железа
- 🔌 **Kernel APIs** — printk, kmalloc, copy_to_user
- 📋 **Module Parameters** — конфигурация модулей
- 🌳 **Device Tree** — описание hardware

**Навыки:**
- Понимание user space vs kernel space
- Написание kernel modules на C
- Создание character device drivers
- Работа с kernel APIs
- Отладка kernel code (dmesg, printk)
- Build system для kernel (Makefile + kbuild)

**Важно:** Kernel programming — это **НЕ обычный C**! Нет stdlib, нет libc, ошибка = kernel panic!

---

## 🎬 Сюжет: Kernel Deep Dive

### День 47, раннее утро — Шэньчжэнь, Kernel Dev Lab

**Li Wei** ведёт Макса в секретную лабораторию. Servers везде. Мониторы показывают kernel logs в реальном времени.

**Li Wei:** *"DJI раньше здесь делали kernel drivers для дронов. Camera streaming, GPS, IMU — всё требовало kernel space performance. User space слишком медленно для real-time control."*

На огромном экране — kernel panic:

```
[    4.123456] BUG: unable to handle kernel NULL pointer dereference
[    4.123457] IP: my_driver+0x42/0x100 [bad_module]
[    4.123458] Oops: 0002 [#1] SMP
[    4.123459] Kernel panic - not syncing: Fatal exception
```

**Макс:** *"Что это?!"*

**Li Wei:** *"Kernel panic. Developer забыл проверить NULL pointer. One bad instruction — вся система упала. Нужен reboot. Data loss. В DJI один такой bug стоил $100,000 когда дрон упал во время demo."*

---

### История

**Li Wei рассказывает:**

*"1991 год. Linus Torvalds, студент из Финляндии, пишет hobby OS. 10,000 строк C кода. Первый Linux kernel."*

```
Linux Kernel Evolution:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1991: Linux 0.01 (10,000 lines)
1992: Loadable modules added (революция!)
1996: Linux 2.0 (1M lines, SMP support)
2001: Linux 2.4 (3M lines, enterprise ready)
2003: Linux 2.6 (5M lines, modern kernel)
2011: Linux 3.0 (15M lines)
2025: Linux 6.x (30M+ lines of code!)

Key insight: Modular architecture = success
```

**Li Wei:** *"Loadable modules — genius idea. Раньше каждый driver compiled in kernel. New hardware = recompile whole kernel = reboot. Modules changed everything. Load on demand. Unload when done. No reboot."*

---

### Миссия

**Виктор (видеозвонок):**

*"Episodes 21-23 — user space. Хорошо. Но нужен custom driver. GPIO для special sensor. User space gpio library слишком медленно. Нужен kernel driver."*

**Дмитрий:** *"Microsecond latency критична. User space не даёт гарантий. Kernel space — real-time control."*

**Алекс (видеозвонок, критично):**

*"Макс, Episodes 21-23 хорошо. Но финальная миссия требует custom kernel driver. Sensor слишком специфичный. No user space library. Kernel driver обязателен."*

**Виктор:** *"Microsecond latency критична. User space даёт milliseconds. Kernel space — microseconds. Mission depends on это."*

**Li Wei:** *"В DJI делал GPIO driver для camera trigger. User space = 10ms jitter. Kernel space = 50μs precision. 200× разница."*

**LILITH (активируется):**

*"Welcome to endgame, Макс. Kernel space — это где Gods живут и mortals умирают. One segfault в user space = process crash. One segfault в kernel = SYSTEM crash. Dirty COW 2016 помнишь? Kernel vulnerability existed с 2007. 9 лет! Privilege escalation любой мог сделать. All because one race condition в kernel memory management. В user space такой bug = annoying. В kernel = catastrophic."*

---

### Цель

**Миссия:** Custom kernel module и device driver

**Требования:**
1. Понять user space vs kernel space
2. Написать простой kernel module
3. Создать character device driver
4. Implement read/write операции
5. Module parameters и sysfs
6. Production deployment и testing

**Сроки:** 5-6 часов

**Li Wei:** *"Episode 21 — GPIO user space. Episode 22 — дроны. Episode 23 — IoT networks. Episode 24 — kernel space. От самого high-level к самому low-level. Final descent. Ready?"*

**LILITH:** *"Kernel programming — это где мальчики становятся мужчинами. Или ломаются и плачут когда видят kernel panic third time today. No garbage collection, no exceptions, no safety. Pure C, pure responsibility. Fuck up once — system dies. Fuck up twice — you're fired. Fuck up three times — you're blacklisted from kernel development forever. Stakes максимальные."*

---

## 🎓 Структура эпизода: 6 микро-циклов

Каждый цикл = 30-40 минут:
- 🎬 Сюжет (2-3 мин)
- 📚 Теория (15-20 мин)
- 💻 Практика (10-15 мин)
- 🤔 Проверка понимания (2 мин)

**Общее время:** ~3 часа теории + 2.5 часа практики = 5-6 часов

---

## 🔄 Цикл 1: User Space vs Kernel Space (35 мин)

### 🎬 Сюжет

**Li Wei рисует диаграмму:**

```
┌─────────────────────────────┐
│    User Space Applications  │ ← printf(), malloc()
├─────────────────────────────┤
│      System Call Interface  │ ← open(), read(), write()
├─────────────────────────────┤
│      Kernel Space           │ ← printk(), kmalloc()
│  - Process Management       │
│  - Memory Management        │
│  - Device Drivers           │
├─────────────────────────────┤
│      Hardware               │ ← CPU, RAM, GPIO, ...
└─────────────────────────────┘
```

**Li Wei:** *"User space — это где живут ваши программы. Kernel space — это где живёт ядро. Между ними — стена. Syscalls — единственная дверь."*

### 📚 Теория: Kernel Architecture

#### User Space vs Kernel Space

**User Space (пользовательское пространство):**
- Где запускаются обычные программы
- Ограниченные привилегии
- Изолированная память
- Может крашнуться без вреда для системы
- Есть libc (printf, malloc, файлы)

**Kernel Space (пространство ядра):**
- Где запускается ядро Linux
- Полные привилегии (ring 0)
- Доступ ко всей памяти
- Крэш = kernel panic = перезагрузка
- НЕТ libc (свои API: printk, kmalloc)

#### 🏠 Метафора: Аэропорт

**User Space = Пассажирская зона:**
```
Пассажиры (программы):
- Могут ходить по терминалу
- НЕ могут на взлётную полосу
- Безопасность контролирует доступ
- Пассажир упал? Только он пострадал
```

**Kernel Space = Служебная зона:**
```
Персонал аэропорта (kernel):
- Доступ везде (полоса, диспетчерская)
- Управляют самолётами (hardware)
- Координируют всё
- Ошибка диспетчера? Катастрофа для всех!
```

**Syscalls = Security checkpoint:**
```
Пассажир хочет багаж (файл читать)?
→ Проходит через security (syscall: open())
→ Персонал проверяет и даёт (kernel checks permissions)
→ Пассажир получает багаж (file descriptor)
```

**LILITH:** *"User space = детский сад с мягкими стенами. Kernel space = nuclear reactor control room. В садике упал — заплакал. В reactor ошибся — Chernobyl. Уровень ответственности несопоставим. User space developers = любители. Kernel developers = professionals (or should be). One mistake = thousands of systems crash."*

#### System Calls

**Как user space общается с kernel:**

```c
// User space код:
FILE *f = fopen("/dev/sensor", "r");  // libc функция
                ↓
       Внутри libc вызывает syscall:
                ↓
       open("/dev/sensor", O_RDONLY);  // syscall
                ↓
       Переход в kernel space (context switch)
                ↓
       Kernel обрабатывает (VFS → driver)
                ↓
       Возврат в user space (context switch)
                ↓
FILE *f теперь содержит file descriptor
```

**Стоимость syscall:**
```
Context switch user → kernel: ~100-500 nanoseconds (modern CPU)

Breakdown:
  • Save user registers        ~20ns
  • Switch to kernel stack     ~30ns
  • Check permissions          ~50ns
  • Execute kernel code        varies
  • Switch back to user        ~50ns

Total overhead: minimum 150ns

Это ДОРОГО для real-time!
10,000 syscalls/sec = 1.5-5ms overhead
```

**Li Wei:** *"DJI camera trigger: 1000 Hz (каждая миллисекунда). User space = syscall каждый раз. 500μs overhead unacceptable. Kernel driver = прямой доступ. <10μs. 50× faster."*

#### Memory Protection

**Virtual Memory:**

```
User Space Process A:     User Space Process B:     Kernel Space:
0x00000000 - 0x7FFFFFFF   0x00000000 - 0x7FFFFFFF   0xC0000000 - 0xFFFFFFFF
       ↓                          ↓                          ↓
  Virtual адреса              Virtual адреса           Direct mapping
       ↓                          ↓                          ↓
    MMU переводит в разные физические адреса          Физическая память
```

**Защита:**
- Process A НЕ может читать память Process B
- User space НЕ может читать kernel memory
- Попытка = segmentation fault

**Li Wei:** *"MMU = Memory Management Unit. Hardware в CPU. Page tables mapping virtual → physical. User процесс пытается read kernel memory? MMU says NO. Page fault. Kernel kills process. В DJI kernel driver ошибка: читал user memory без copy_from_user(). MMU page fault. Kernel panic. System crash during flight demo. Disaster."*

**💡 "Aha!" момент: Почему kernel module опаснее чем rootkit?**

<details>
<summary>Откройте чтобы понять</summary>

**User space rootkit (с root правами):**
```
Может:
- Читать файлы ✅
- Запускать процессы ✅
- Менять конфиги ✅

НЕ может:
- Скрыть себя от ps (kernel видит всё)
- Перехватить syscalls (kernel контролирует)
- Модифицировать kernel code (защищено)
```

**Kernel module rootkit:**
```
Может ВСЁ:
- Скрыть процессы (модифицировать /proc)
- Перехватить syscalls (hook в kernel)
- Скрыть файлы (hook VFS)
- Скрыть сетевые соединения (hook netfilter)
- Стать НЕВИДИМЫМ для антивируса

Почему?
Kernel module = часть kernel
Kernel доверяет своим модулям
Нет проверок, нет песочницы
```

**Реальный пример — Adore-ng rootkit (2004):**
```
Loadable kernel module (adore-ng.ko)
Hooks:
  • sys_getdents64() → hide files
  • sys_read() → hide processes from /proc
  • tcp4_seq_show() → hide network connections
  • packet_rcv() → hide network traffic

Result:
  → Полностью невидимый для всех tools
  → ps, ls, netstat - ничего не видят
  → Only way to detect: memory forensics
  → chkrootkit, rkhunter - бесполезны
```

**Современная защита:**
```
Secure Boot:
  ✓ Only signed modules load
  ✓ UEFI checks signature
  ✓ Invalid signature = boot fails

Kernel Module Signing (CONFIG_MODULE_SIG):
  ✓ Every .ko must be signed
  ✓ Public key in kernel
  ✓ Unsigned module = rejected

Lockdown mode (Linux 5.4+):
  ✓ Prevents /dev/mem access
  ✓ Prevents kexec
  ✓ Prevents hibernation exploits
```

**Li Wei:** *"Kernel module = superpower. В DJI access к kernel modules строго controlled. Code review обязателен. Two senior engineers sign off. One malicious module = full fleet compromise. 10,000 дронов под контролем attacker. Реальный risk."*

**LILITH:** *"Dirty COW (2016) — kernel bug, не module. But показал что kernel vulnerabilities = game over. 9 лет bug существовал. Любой user → root. All because race condition в copy-on-write. Kernel module with intentional backdoor? Worse. Поэтому Secure Boot critical. Trust но verify. Actually, don't trust — verify everything."*

</details>

---

### 💻 Практика: Kernel Space Exploration

**Задание:**

1. **Проверить kernel version:**
```bash
uname -r
# 5.15.0-91-generic

ls /lib/modules/$(uname -r)/
# Kernel modules директория
```

2. **Посмотреть загруженные модули:**
```bash
lsmod | head -20

# Columns:
# Module - имя модуля
# Size - размер в памяти
# Used by - сколько процессов используют
```

3. **Информация о модуле:**
```bash
modinfo bluetooth

# filename:       /lib/modules/.../bluetooth.ko
# license:        GPL
# description:    Bluetooth Core ver 2.22
# author:         Marcel Holtmann <marcel@holtmann.org>
```

4. **Kernel ring buffer (логи):**
```bash
dmesg | tail -30

# Kernel printk() выводит сюда
# Каждое сообщение с timestamp
# Уровни: emerg, alert, crit, err, warning, notice, info, debug
```

**Li Wei:** *"dmesg — это окно в kernel. Каждый printk() попадает сюда. Driver crash? dmesg покажет. Module load? dmesg знает. В DJI первое что делали при debug — dmesg | grep driver_name."*

5. **Syscall trace (strace):**
```bash
strace ls /tmp 2>&1 | head -20

# Видим ВСЕ syscalls:
# openat(), getdents(), write(), close()
```

---

### 🤔 Проверка понимания

**LILITH:** *"Kernel module может использовать printf() и malloc() из libc. Правда или ложь?"*

<details>
<summary>🤔 Kernel APIs vs libc</summary>

**Ответ:** **ЛОЖЬ! Kernel НЕ имеет libc!**

**Проблема:**

**libc (user space):**
- printf() выводит в stdout (file descriptor)
- malloc() вызывает syscall brk()/mmap()
- FILE* работает через syscalls

**Kernel space:**
- НЕТ stdout (это user space концепция!)
- НЕТ syscalls (kernel САМ их реализует!)
- НЕТ libc вообще

**Вместо этого kernel предоставляет:**

```c
// User space:          Kernel space:

printf()        →       printk()
malloc()        →       kmalloc() / vmalloc()
free()          →       kfree()
memcpy()        →       memcpy() (есть!)
sprintf()       →       snprintf() (есть!)
fopen()         →       filp_open()
sleep()         →       msleep() / schedule_timeout()
```

**Почему нет libc?**

```
1. Kernel запускается ПЕРВЫМ
   → libc ещё не загружена
   → libc сама зависит от kernel

2. Kernel НЕ процесс
   → Нет address space как у процесса
   → libc предполагает процесс

3. Performance
   → libc делает syscalls
   → Kernel УЖЕ в kernel space
   → Зачем syscall самому себе?
```

**Пример ошибки:**

```c
// НЕПРАВИЛЬНО (не скомпилируется):
#include <stdio.h>
printf("Hello\n");

// ПРАВИЛЬНО:
#include <linux/kernel.h>
printk(KERN_INFO "Hello\n");
```

**Li Wei:** *"Первая ошибка всех beginners — пытаться использовать libc в kernel. Compiler сразу говорит NO. Kernel — это foundation. libc строится НАД kernel. Foundation не может использовать то что на нём построено. Это как стоять на собственных плечах — физически невозможно."*

**LILITH:** *"Видел как junior dev включил <stdlib.h> в kernel module. 200 compiler errors. Он думал 'just different library'. NO. Это совершенно другой world. User space = high-level. Kernel space = low-level. No training wheels. No safety nets. Learn the hard way or don't learn at all."*

</details>

---

[Продолжение следует...]

*Part 1/3 of Episode 24 README.md*
*Циклы 2-6 + финал в следующей части*
## 🔄 Цикл 2: Kernel Module Basics (40 мин)

### 🎬 Сюжет

**Li Wei пишет код:**

```c
#include <linux/module.h>
#include <linux/kernel.h>

static int __init my_init(void) {
    printk(KERN_INFO "Module loaded\n");
    return 0;
}

static void __exit my_exit(void) {
    printk(KERN_INFO "Module unloaded\n");
}

module_init(my_init);
module_exit(my_exit);
```

**Li Wei:** *"30 строк. Kernel module готов. Compile, insmod, работает. Но каждая строка критична. __init — optimization. KERN_INFO — log level. return 0 — success. Ошибка = kernel panic."*

### 📚 Теория: Kernel Module Programming

#### Минимальный модуль

**Обязательные компоненты:**

```c
#include <linux/module.h>    // MODULE_LICENSE, module_init
#include <linux/kernel.h>    // printk, KERN_*

// License (ОБЯЗАТЕЛЬНО!)
MODULE_LICENSE("GPL");

// Init function
static int __init hello_init(void) {
    printk(KERN_INFO "Hello!\n");
    return 0;  // 0 = success, negative = error
}

// Exit function
static void __exit hello_exit(void) {
    printk(KERN_INFO "Goodbye!\n");
}

// Register functions
module_init(hello_init);
module_exit(hello_exit);
```

#### Module Metadata

**Описание модуля:**

```c
MODULE_LICENSE("GPL");           // Обязательно!
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("My Module");
MODULE_VERSION("1.0");
```

**Почему MODULE_LICENSE обязателен?**

```
GPL modules:
- Могут использовать все kernel APIs
- Могут быть включены в mainline kernel
- Taint flag: нет

Proprietary modules:
- Некоторые APIs недоступны (EXPORT_SYMBOL_GPL)
- Kernel помечается "tainted"
- Support сложнее
```

#### printk() и Log Levels

**printk() = printf() для kernel:**

```c
printk(KERN_EMERG   "System unusable\n");    // 0 - highest
printk(KERN_ALERT   "Action needed\n");      // 1
printk(KERN_CRIT    "Critical\n");           // 2
printk(KERN_ERR     "Error\n");              // 3
printk(KERN_WARNING "Warning\n");            // 4
printk(KERN_NOTICE  "Notice\n");             // 5
printk(KERN_INFO    "Info\n");               // 6
printk(KERN_DEBUG   "Debug\n");              // 7 - lowest

// Старый style (не использовать):
printk("<4>Warning\n");  // число = level
```

**Где выводится?**

```bash
# Kernel ring buffer
dmesg

# Или syslog (если configured)
/var/log/kern.log
/var/log/syslog
```

#### __init и __exit Macros

**Memory optimization:**

```c
static int __init my_init(void) { ... }
static void __exit my_exit(void) { ... }
```

**Что делают?**

```
__init:
- После загрузки модуля init() больше не нужна
- Kernel освобождает эту память
- Экономия RAM

__exit:
- Если модуль built-in (не loadable), exit() никогда не вызовется
- Можно вообще не компилировать
- Экономия ROM
```

**💡 "Aha!" момент: Почему return 0 в init критичен?**

<details>
<summary>Откройте чтобы понять</summary>

**Init function return values:**

```c
static int __init my_init(void) {
    // Setup code...

    if (error) {
        return -ENOMEM;  // Error code
    }

    return 0;  // Success
}
```

**Что происходит:**

**return 0 (success):**
```
insmod my_module.ko
→ kernel вызывает my_init()
→ return 0
→ Kernel: "OK, module loaded"
→ lsmod показывает module
→ Всё хорошо
```

**return -ENOMEM (error):**
```
insmod my_module.ko
→ kernel вызывает my_init()
→ return -ENOMEM
→ Kernel: "Init failed!"
→ Kernel автоматически вызывает my_exit() (cleanup!)
→ Module НЕ загружен
→ insmod возвращает error
```

**Ключевой момент:**
```
Kernel АВТОМАТИЧЕСКИ делает cleanup при ошибке!
1. Вызывает exit()
2. Освобождает выделенную память
3. Unregisters всё что зарегистрировано

НО: Это работает только если вы правильно cleanup в exit()!
```

**Пример:**

```c
static int ptr;

static int __init my_init(void) {
    ptr = kmalloc(1024, GFP_KERNEL);
    if (!ptr) {
        return -ENOMEM;  // Kernel вызовет exit()
    }

    // ... другая инициализация
    if (другая_ошибка) {
        kfree(ptr);  // Cleanup вручную!
        return -EINVAL;
    }

    return 0;
}

static void __exit my_exit(void) {
    kfree(ptr);  // Всегда cleanup
}
```

**Li Wei:** *"return 0 — это не просто 'всё ОК'. Это contract с kernel: 'Я взял ресурсы и гарантирую cleanup в exit()'. Нарушил contract — memory leak или worse, use-after-free."*

</details>

---

### 💻 Практика: First Kernel Module

**Задание:**

1. **Install kernel headers:**
```bash
sudo apt install -y linux-headers-$(uname -r)

# Проверить
ls /lib/modules/$(uname -r)/build
```

2. **Complete starter module:**
```bash
cd ~/kernel-shadows/season-06-embedded-iot/episode-24-kernel/starter/c-code

# Edit hello_module.c (complete TODOs)
nano hello_module.c
```

3. **Build module:**
```bash
make

# Должен создаться hello_module.ko
ls -lh *.ko
```

4. **Load module:**
```bash
sudo insmod hello_module.ko

# Check it loaded
lsmod | grep hello
```

5. **Check kernel log:**
```bash
dmesg | tail -5
# Должно быть: "Hello from kernel!"
```

6. **Unload module:**
```bash
sudo rmmod hello_module

dmesg | tail -2
# Должно быть: "Goodbye from kernel!"
```

---

## 🔄 Цикл 3: Character Device Drivers (45 мин)

### 🎬 Сюжет

**Li Wei:** *"/dev/zero, /dev/null, /dev/random — это всё character devices. Kernel drivers. Когда user space делает open('/dev/random'), kernel вызывает driver code. Мы создадим свой device."*

### 📚 Теория: Character Devices

#### Что такое Character Device?

**Types of devices:**

```
Character Device:      Block Device:        Network Device:
- /dev/tty             - /dev/sda           - eth0, wlan0
- /dev/random          - /dev/mmcblk0       - Packets
- Байт за байтом       - Блоки (512B+)     - Special
- Stream               - Random access     - No /dev entry
```

**Character device = поток байтов:**
```
User читает: a b c d e f g h ...
             ↑ по одному или несколько
```

#### File Operations

**Driver реализует операции:**

```c
#include <linux/fs.h>

static struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = dev_open,       // open()
    .release = dev_release, // close()
    .read = dev_read,       // read()
    .write = dev_write,     // write()
    .llseek = dev_llseek,   // lseek()
    .unlocked_ioctl = dev_ioctl, // ioctl()
};
```

**Когда user space вызывает:**

```c
// User space:
int fd = open("/dev/mydev", O_RDWR);
→ Kernel вызывает: fops->open()

write(fd, "hello", 5);
→ Kernel вызывает: fops->write()

read(fd, buf, 100);
→ Kernel вызывает: fops->read()

close(fd);
→ Kernel вызывает: fops->release()
```

#### Register Character Device

**Major/Minor numbers:**

```
/dev/sda1 = Block device, major=8, minor=1
/dev/tty0 = Char device, major=4, minor=0

Major number = тип устройства
Minor number = конкретное устройство
```

**Registration:**

```c
#include <linux/fs.h>

static int major_number;

// Register
major_number = register_chrdev(0, "mydev", &fops);
//                              ↑
//                         0 = auto-allocate major

// Unregister
unregister_chrdev(major_number, "mydev");
```

#### copy_to_user / copy_from_user

**КРИТИЧНО: НЕ можно просто memcpy!**

```c
// НЕПРАВИЛЬНО (kernel panic!):
static ssize_t dev_read(struct file *f, char *buffer,
                        size_t len, loff_t *off) {
    memcpy(buffer, kernel_data, len);  // ❌ CRASH!
    return len;
}

// ПРАВИЛЬНО:
static ssize_t dev_read(struct file *f, char __user *buffer,
                        size_t len, loff_t *off) {
    if (copy_to_user(buffer, kernel_data, len))
        return -EFAULT;
    return len;
}
```

**Почему copy_to_user?**

```
User space buffer находится в другом address space!
Прямой memcpy = доступ к невалидной памяти = kernel panic

copy_to_user:
1. Проверяет что user buffer валиден
2. Проверяет permissions
3. Безопасно копирует через MMU
4. Возвращает 0 если OK, non-zero если error
```

---

### 💻 Практика: Character Device Driver

**Задание:**

1. **Study example:**
```bash
cd ~/kernel-shadows/season-06-embedded-iot/episode-24-kernel/artifacts/examples

# Read char_device.c
less char_device.c
```

2. **Build and load:**
```bash
make
sudo insmod char_device.ko

# Check device created
ls -l /dev/mychardev
# crw------- 1 root root 243, 0 Oct 13 17:00 /dev/mychardev
#  ↑                 ↑    ↑
#  char device    major minor
```

3. **Test write:**
```bash
echo "Hello from user space!" | sudo tee /dev/mychardev

# Check kernel log
dmesg | tail -2
# Wrote 23 bytes
```

4. **Test read:**
```bash
sudo cat /dev/mychardev
# Hello from user space!
```

5. **Unload:**
```bash
sudo rmmod char_device

# Device should be gone
ls -l /dev/mychardev
# ls: cannot access '/dev/mychardev': No such file or directory
```

---

## 🔄 Цикл 4: Module Parameters & sysfs (30 мин)

### 🎬 Сюжет

**Li Wei:** *"Модуль с hardcoded values негибок. Module parameters — как command-line args. sysfs — runtime configuration. Real-time tuning без перезагрузки."*

### 📚 Теория: Module Configuration

#### Module Parameters

**Declare parameters:**

```c
static int debug = 0;
module_param(debug, int, 0644);
MODULE_PARM_DESC(debug, "Debug level (0=off, 1=on)");

static char *name = "default";
module_param(name, charp, 0644);
MODULE_PARM_DESC(name, "Device name");
```

**Load with parameters:**

```bash
sudo insmod mymodule.ko debug=1 name="sensor"

# Check parameters
cat /sys/module/mymodule/parameters/debug
# 1
```

**Permissions (0644):**
```
0644 = rw-r--r--
Owner: read/write
Others: read only

0444 = r--r--r-- (read-only)
0000 = hidden in sysfs
```

#### sysfs Interface

**Create sysfs entries:**

```c
static ssize_t show_value(struct device *dev,
                          struct device_attribute *attr,
                          char *buf) {
    return sprintf(buf, "%d\n", my_value);
}

static ssize_t store_value(struct device *dev,
                           struct device_attribute *attr,
                           const char *buf, size_t count) {
    sscanf(buf, "%d", &my_value);
    return count;
}

static DEVICE_ATTR(value, 0644, show_value, store_value);
```

**Access from user space:**

```bash
# Read
cat /sys/class/mydev/mydevice/value

# Write
echo 100 > /sys/class/mydev/mydevice/value
```

---

### 💻 Практика: Module Parameters

```bash
# Load with parameters
sudo insmod hello_complete.ko name="Kernel Hacker"

# Check sysfs
cat /sys/module/hello_complete/parameters/name
# Kernel Hacker

# Change at runtime (if writable)
echo "Admin" | sudo tee /sys/module/hello_complete/parameters/name
```

---

## 🔄 Цикл 5: Kernel APIs & Memory Management (35 мин)

### 🎬 Сюжет

**Li Wei:** *"Kernel memory отличается от user space. kmalloc, vmalloc, GFP flags. Атомарность, interrupt context. Memory leak в kernel = система деградирует. Cleanup критичен."*

### 📚 Теория: Kernel Memory

#### Memory Allocation

**kmalloc vs vmalloc:**

```c
// kmalloc - физически непрерывная память
void *ptr = kmalloc(size, GFP_KERNEL);
kfree(ptr);

// vmalloc - виртуально непрерывная
void *ptr = vmalloc(size);
vfree(ptr);
```

**GFP Flags:**

```c
GFP_KERNEL  - Обычный (может спать)
GFP_ATOMIC  - Atomic context (НЕ может спать!)
GFP_DMA     - DMA-capable memory
```

**Когда что использовать:**

```
kmalloc + GFP_KERNEL:
- Process context
- Можем спать (sleep)
- Размер < PAGE_SIZE (обычно 4KB)

kmalloc + GFP_ATOMIC:
- Interrupt context
- НЕ можем спать!
- Быстрая аллокация

vmalloc:
- Большие буферы (> PAGE_SIZE)
- Process context
- Медленнее чем kmalloc
```

#### Timing Functions

```c
#include <linux/delay.h>

msleep(1000);        // Sleep 1 second (может спать)
mdelay(1000);        // Busy-wait 1 second (НЕ спит!)
udelay(100);         // Microsecond delay
```

---

### 💻 Практика: Memory Management

```c
static char *buffer;

static int __init my_init(void) {
    buffer = kmalloc(1024, GFP_KERNEL);
    if (!buffer) {
        printk(KERN_ERR "kmalloc failed\n");
        return -ENOMEM;
    }

    strcpy(buffer, "Hello");
    printk(KERN_INFO "Buffer: %s\n", buffer);
    return 0;
}

static void __exit my_exit(void) {
    if (buffer) {
        kfree(buffer);
        printk(KERN_INFO "Buffer freed\n");
    }
}
```

---

## 🔄 Цикл 6: Device Tree & Hardware Integration (30 мин)

### 🎬 Сюжет — День 48, production deployment

**Li Wei:** *"ARM системы используют Device Tree. Описание hardware в .dts файлах. Kernel парсит при загрузке. Driver матчится по compatible string. Zero hardcoding."*

### 📚 Теория: Device Tree

**Device Tree Structure:**

```dts
/ {
    compatible = "raspberrypi,4-model-b";

    gpio: gpio@7e200000 {
        compatible = "brcm,bcm2835-gpio";
        reg = <0x7e200000 0xb4>;
    };

    sensor@0 {
        compatible = "mycompany,mysensor";
        reg = <0x50>;
        gpio = <&gpio 17 0>;
    };
};
```

**Driver matching:**

```c
static const struct of_device_id my_driver_match[] = {
    { .compatible = "mycompany,mysensor" },
    { },
};
MODULE_DEVICE_TABLE(of, my_driver_match);

static struct platform_driver my_driver = {
    .driver = {
        .name = "mysensor",
        .of_match_table = my_driver_match,
    },
    .probe = my_probe,
    .remove = my_remove,
};
```

---

### 💻 Практика: Production Deployment

```bash
# Load module at boot
sudo cp mymodule.ko /lib/modules/$(uname -r)/kernel/drivers/

# Update module dependencies
sudo depmod -a

# Auto-load
echo "mymodule" | sudo tee -a /etc/modules

# Reboot and verify
sudo reboot

# After reboot:
lsmod | grep mymodule
```

---

## 🎯 Финальное задание

### Сюжет — Kernel Driver Deployed

**Виктор:** *"Custom driver готов?"*

**Макс:** *"Да. Character device driver. Sub-microsecond latency. Module parameters для tuning. sysfs interface. Production deployed."*

**Li Wei:** *"Season 6 завершён. Episode 21 — GPIO user space. Episode 22 — дроны. Episode 23 — IoT. Episode 24 — kernel space. From abstraction к silicon. Full stack embedded engineer."*

**LILITH:** *"От shell scripts (Season 1) к kernel modules. Journey complete. Ты теперь можешь: code любой level (user/kernel), hack системы, secure их (Season 5), управлять дронами, программировать kernel. Multi-layer engineer. Rare и ценный skill set."*

---

### Итоговая работа

**Обязательно:**

- [ ] Kernel module компилируется
- [ ] insmod/rmmod работают
- [ ] dmesg показывает логи
- [ ] Character device создан
- [ ] Read/write операции работают
- [ ] Module parameters применены

---

## 🧪 Автотесты

```bash
cd ~/kernel-shadows/season-06-embedded-iot/episode-24-kernel
./tests/test.sh
```

---

## 📚 Ресурсы

- **Linux Kernel Module Programming Guide:** https://sysprog21.github.io/lkmpg/
- **Linux Device Drivers (LDD3):** https://lwn.net/Kernel/LDD3/
- **Kernel Source:** https://kernel.org/

---

## 🎓 Итоги Episode 24

**Что изучили:**
- ✅ User space vs kernel space
- ✅ Kernel module basics
- ✅ Character device drivers
- ✅ Kernel APIs (printk, kmalloc)
- ✅ Module parameters & sysfs
- ✅ Device Tree integration

---

## 🏆 SEASON 6 COMPLETE!

**Embedded Linux & IoT Security Master! 🔧**

**Макс освоил:**
- Episode 21: Raspberry Pi & GPIO (user space)
- Episode 22: Дроны & MAVLink (autonomous flight)
- Episode 23: IoT & MQTT (sensor networks)
- Episode 24: Kernel Modules (kernel space)

**From user space to kernel space. From apps to silicon. Full embedded stack.**

---

**Статус:** Episode 24 ЗАВЕРШЁН ✅
**Статус:** SEASON 6 ЗАВЕРШЁН ✅
**Далее:** Season 7 или другие задачи
**Курс:** [KERNEL SHADOWS](../../../)

---

*"Kernel space — это где abstraction заканчивается и начинается реальность. Welcome to the deep end."* — Li Wei
