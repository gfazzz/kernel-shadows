# KERNEL SHADOWS: С чего начать?
## Пошаговое руководство для новичков

<div align="center">

**"Каждый эксперт когда-то был новичком. Начнём твой путь."** — LILITH

[![Сложность](https://img.shields.io/badge/difficulty-beginner-green)]()
[![Время](https://img.shields.io/badge/setup-20--30min-blue)]()
[![Платформа](https://img.shields.io/badge/platform-Ubuntu_Linux-orange)]()

</div>

---

## 📋 Содержание

1. [Требования к системе](#требования-к-системе)
2. [Установка Ubuntu](#установка-ubuntu)
3. [Подготовка окружения](#подготовка-окружения)
4. [Клонирование репозитория](#клонирование-репозитория)
5. [Первый эпизод](#первый-эпизод)
6. [Troubleshooting](#troubleshooting)
7. [Получить помощь](#получить-помощь)

---

## ⚙️ Требования к системе

### Минимальные требования:
- **ОС:** Ubuntu 20.04 LTS или новее (рекомендуется 22.04/24.04 LTS)
- **CPU:** 2 ядра (x86_64)
- **RAM:** 4 GB (рекомендуется 8 GB)
- **Диск:** 20 GB свободного места
- **Интернет:** Стабильное подключение для установки пакетов

### Рекомендуемые требования:
- **ОС:** Ubuntu 24.04 LTS
- **CPU:** 4+ ядра
- **RAM:** 8+ GB
- **Диск:** 50+ GB (SSD)
- **Терминал:** GNOME Terminal, Alacritty, или любой другой

### Проверка версии Ubuntu:
```bash
lsb_release -a
# Ожидаемый вывод:
# Distributor ID: Ubuntu
# Description:    Ubuntu 24.04 LTS
# Release:        24.04
# Codename:       noble
```

---

## 🐧 Установка Ubuntu

У вас есть **три варианта** установки Ubuntu в зависимости от вашей текущей операционной системы.

### Вариант 1: Native Ubuntu (Linux на основной системе)

**Для кого:** Linux пользователи, dual-boot, или переход с другой ОС.

**Установка:**
1. Скачайте ISO образ: [ubuntu.com/download/desktop](https://ubuntu.com/download/desktop)
2. Создайте загрузочную флешку: [rufus.ie](https://rufus.ie/) (Windows) или `dd` (Linux)
3. Загрузитесь с флешки и следуйте инструкциям установщика

**Плюсы:**
- ✅ Максимальная производительность
- ✅ Полный доступ к оборудованию
- ✅ Лучший опыт работы с Linux

**Минусы:**
- ⚠️ Требует перезагрузку для переключения ОС (если dual-boot)
- ⚠️ Требует разбивку диска

---

### Вариант 2: WSL2 (Windows Subsystem for Linux)

**Для кого:** Пользователи Windows 10/11, которые хотят Ubuntu без перезагрузки.

**Требования:**
- Windows 10 версия 2004+ или Windows 11
- Virtualization включена в BIOS

**Установка (PowerShell от администратора):**
```powershell
# Установить WSL2
wsl --install

# Установить Ubuntu (по умолчанию последняя LTS версия)
wsl --install -d Ubuntu

# Или конкретную версию:
wsl --install -d Ubuntu-24.04
```

**Первый запуск:**
1. Откройте "Ubuntu" из меню Пуск
2. Создайте пользователя и пароль
3. Обновите систему:
```bash
sudo apt update && sudo apt upgrade -y
```

**Проверка версии:**
```bash
lsb_release -a
uname -a  # Должен показать WSL2 kernel
```

**Плюсы:**
- ✅ Не требует перезагрузку
- ✅ Интеграция с Windows (доступ к файлам)
- ✅ Быстрая установка

**Минусы:**
- ⚠️ Некоторые низкоуровневые вещи могут работать иначе
- ⚠️ GUI приложения требуют дополнительной настройки

**Рекомендация для курса:** WSL2 **отлично подходит** для Seasons 1-5. Для Season 6 (Embedded Linux) может потребоваться native Linux.

---

### Вариант 3: Виртуальная машина (VirtualBox / VMware)

**Для кого:** Пользователи macOS, Windows, или те кто хочет изолированную среду.

**Установка:**

#### Шаг 1: Установите гипервизор
- **VirtualBox:** [virtualbox.org](https://www.virtualbox.org/) (бесплатно)
- **VMware Workstation Player:** [vmware.com](https://www.vmware.com/) (бесплатно для личного использования)

#### Шаг 2: Создайте виртуальную машину
1. Скачайте Ubuntu ISO: [ubuntu.com/download/desktop](https://ubuntu.com/download/desktop)
2. Создайте новую VM:
   - **Имя:** KERNEL-SHADOWS
   - **Тип:** Linux
   - **Версия:** Ubuntu (64-bit)
   - **RAM:** 4096 MB (минимум), 8192 MB (рекомендуется)
   - **Диск:** 30 GB (динамически расширяемый)
   - **CPU:** 2+ ядра
3. Подключите ISO образ как виртуальный CD
4. Запустите VM и установите Ubuntu

#### Шаг 3: Установите Guest Additions (VirtualBox)
```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
# Вставьте Guest Additions CD через меню VirtualBox
# Devices -> Insert Guest Additions CD image
cd /media/$USER/VBox*
sudo ./VBoxLinuxAdditions.run
sudo reboot
```

**Плюсы:**
- ✅ Изолированная среда (безопасно экспериментировать)
- ✅ Снимки (snapshots) — можно откатиться
- ✅ Работает на любой ОС

**Минусы:**
- ⚠️ Меньшая производительность
- ⚠️ Требует больше ресурсов от хост-системы

---

## 🛠️ Подготовка окружения

После установки Ubuntu выполните следующие шаги:

### 1. Обновите систему
```bash
sudo apt update && sudo apt upgrade -y
```

**Что это делает:**
- `apt update` — обновляет список доступных пакетов
- `apt upgrade` — устанавливает обновления для установленных пакетов
- `sudo` — выполняет команду с правами администратора
- `-y` — автоматически отвечает "yes" на все вопросы

### 2. Установите базовые инструменты
```bash
sudo apt install -y \
  git \
  curl \
  wget \
  vim \
  nano \
  tree \
  htop \
  net-tools \
  man-db \
  bash-completion
```

**Что установлено:**
- `git` — система контроля версий (для клонирования курса)
- `curl`, `wget` — загрузка файлов из интернета
- `vim`, `nano` — текстовые редакторы для терминала
- `tree` — визуализация структуры директорий
- `htop` — мониторинг процессов
- `net-tools` — сетевые утилиты (ifconfig, netstat)
- `man-db` — man-страницы (документация)
- `bash-completion` — автодополнение команд

### 3. Настройте Git (опционально, но рекомендуется)
```bash
git config --global user.name "Ваше Имя"
git config --global user.email "ваш@email.com"
git config --global core.editor "nano"  # или "vim"
```

### 4. Проверка готовности
```bash
# Проверка версий инструментов
git --version          # Должна быть >= 2.30
bash --version         # Должна быть >= 5.0
python3 --version      # Должна быть >= 3.8 (обычно предустановлен)

# Проверка доступных команд
which ls cd pwd cat grep find  # Все должны быть найдены
```

Если все команды работают — вы готовы! 🎉

---

## 📥 Клонирование репозитория

### 1. Выберите директорию для курса
```bash
# Создайте директорию для проектов (если её нет)
mkdir -p ~/projects
cd ~/projects
```

**Что это делает:**
- `mkdir -p` — создаёт директорию (флаг `-p` создаёт родительские директории если нужно)
- `cd` — переходит в созданную директорию
- `~` — сокращение для домашней директории (`/home/ваш_пользователь`)

### 2. Клонируйте репозиторий
```bash
git clone https://github.com/gfazzz/kernel-shadows.git
cd kernel-shadows
```

**Ожидаемый вывод:**
```
Cloning into 'kernel-shadows'...
remote: Enumerating objects: 150, done.
remote: Counting objects: 100% (150/150), done.
remote: Compressing objects: 100% (95/95), done.
remote: Total 150 (delta 45), reused 130 (delta 35)
Receiving objects: 100% (150/150), 250.00 KiB | 1.50 MiB/s, done.
Resolving deltas: 100% (45/45), done.
```

### 3. Проверка структуры
```bash
ls -la
tree -L 2  # Показать структуру директорий (2 уровня)
```

**Ожидаемая структура:**
```
kernel-shadows/
├── README.md
├── GETTING_STARTED.md (этот файл)
├── SCENARIO.md
├── CURRICULUM.md
├── LICENSE
├── season-01-shell-foundations/
│   ├── data/                          # учебные данные для практики
│   ├── s01e01-terminal-awakening/     # атомарные серии v2.0 (sNNeNN)
│   ├── s01e02-ls-look-around/
│   └── … s01e14-batch-report/
└── ...
```

---

## 🚀 Первая серия

Курс v2.0 разбит на **атомарные серии** `sNNeNN` (один концепт — одна задача).
Начните с первой — **s01e01: Terminal Awakening**. Ниже — общий порядок; точные
команды и артефакт каждой серии смотрите в её `README.md` и `mission.md`
(карта всех 12 серий Season 1 — в [season-1 README](season-01-shell-foundations/README.md)).

### Шаг 1: Перейдите в директорию эпизода
```bash
cd ~/projects/kernel-shadows/season-01-shell-foundations/s01e01-terminal-awakening
```

### Шаг 2: Прочитайте интегрированное руководство
```bash
less README.md
# или открыть в текстовом редакторе (лучше для навигации по спойлерам):
nano README.md
```

**Клавиши для `less`:**
- `Space` — следующая страница
- `b` — предыдущая страница
- `/текст` — поиск
- `q` — выход

### Шаг 3: Изучите теорию
```bash
cat README.md | less
# или открыть в браузере для форматирования:
# (если есть GUI)
xdg-open README.md  # Linux
# или просто читайте на GitHub:
# https://github.com/gfazzz/kernel-shadows/tree/main/season-01-shell-foundations/s01e01-terminal-awakening
```

### Шаг 4: Запустите starter script (если есть)
```bash
# Проверьте наличие starter.sh
ls -la starter.sh

# Сделайте его исполняемым
chmod +x starter.sh

# Запустите
./starter.sh
```

**Что делает `starter.sh`:**
- Проверяет зависимости
- Создаёт тестовое окружение
- Настраивает артефакты для миссии

### Шаг 5: Выполните миссию

⚠️ **ВАЖНО:** В Episode 01 вы работаете с **локальной симуляцией** удалённого сервера.

**Почему локально?**
- Для практики не нужен реальный удалённый сервер
- Симуляция даёт тот же опыт, но безопаснее
- Вы можете экспериментировать без риска

**Как работает симуляция:**
```bash
# Миссия попросит вас "подключиться к серверу"
# Но на самом деле вы будете работать с локальной копией:

cd artifacts/test_environment
ls -la
# Это ваш "удалённый сервер"
```

Следуйте заданиям из `README.md` (там 8 последовательных заданий).

### Шаг 6: Проверьте решение
```bash
cd tests
chmod +x test.sh
./test.sh
```

**Ожидаемый вывод при успехе:**
```
✅ TEST 1: PASSED — briefing.txt найден
✅ TEST 2: PASSED — .secret_location найден
✅ TEST 3: PASSED — .next_server найден
✅ TEST 4: PASSED — find_files.sh работает корректно

╔══════════════════════════════════════════════════════════╗
║  🎉 МИССИЯ ЗАВЕРШЕНА!                                     ║
║                                                            ║
║  Макс, ты справился с первой миссией.                       ║
║  Виктор будет доволен.                                     ║
║                                                            ║
║  Следующий эпизод: Episode 02 - Shell Scripting Basics    ║
╚══════════════════════════════════════════════════════════╝
```

### Шаг 7: Следующий эпизод
```bash
cd ../s01e02-ls-look-around
less README.md
```

---

## 🔧 Troubleshooting

### Проблема 1: `git: command not found`
**Решение:**
```bash
sudo apt update
sudo apt install -y git
```

### Проблема 2: `Permission denied` при клонировании
**Причина:** У вас нет прав на запись в директорию.

**Решение:**
```bash
# Клонируйте в домашнюю директорию:
cd ~
mkdir projects
cd projects
git clone https://github.com/gfazzz/kernel-shadows.git
```

### Проблема 3: `./starter.sh: Permission denied`
**Причина:** Скрипт не имеет прав на выполнение.

**Решение:**
```bash
chmod +x starter.sh
./starter.sh
```

### Проблема 4: `bash: tree: command not found`
**Решение:**
```bash
sudo apt install -y tree
```

### Проблема 5: Медленная установка пакетов (apt)
**Причина:** Медленные зеркала (mirrors).

**Решение:**
```bash
# Выберите ближайшее зеркало
sudo apt install -y software-properties-common
sudo add-apt-repository main
sudo apt update
```

Или используйте GUI: **Software & Updates** → **Download from:** → Выберите ближайший сервер.

### Проблема 6: WSL2 — нет доступа к файлам Windows
**Решение:**
```bash
# Файлы Windows доступны через /mnt/
cd /mnt/c/Users/ВашеИмя/Desktop
ls -la
```

**Копировать файлы в WSL:**
```bash
cp /mnt/c/Users/ВашеИмя/file.txt ~/projects/
```

### Проблема 7: Терминал некорректно отображает символы
**Причина:** Некорректная локаль (locale).

**Решение:**
```bash
# Проверьте текущую локаль
locale

# Установите UTF-8
sudo apt install -y locales
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

# Перезапустите терминал
```

### Проблема 8: `sudo: unable to resolve host`
**Причина:** Некорректная настройка hostname в `/etc/hosts`.

**Решение:**
```bash
# Проверьте hostname
hostname

# Добавьте его в /etc/hosts
sudo nano /etc/hosts
# Добавьте строку:
# 127.0.0.1   ваш_hostname

# Пример:
# 127.0.0.1   ubuntu-vm
```

---

## 🆘 Получить помощь

### 📚 Документация курса
- **README.md** — обзор курса
- **SCENARIO.md** — сюжет и персонажи
- **CURRICULUM.md** — программа обучения
- **RESOURCES.md** — рекомендуемые ресурсы

### 🐛 Нашли баг?
Создайте issue: [github.com/gfazzz/kernel-shadows/issues](https://github.com/gfazzz/kernel-shadows/issues)

**Шаблон issue:**
```markdown
**Эпизод:** Season 1, Episode 01
**ОС:** Ubuntu 24.04 LTS (WSL2 / Native / VM)
**Проблема:** [краткое описание]

**Шаги для воспроизведения:**
1. ...
2. ...

**Ожидаемый результат:** ...
**Фактический результат:** ...

**Логи/Ошибки:**
```
[вставьте вывод команды]
```
```

### 💬 Обсуждения
Задайте вопрос: [github.com/gfazzz/kernel-shadows/discussions](https://github.com/gfazzz/kernel-shadows/discussions)

### 📖 Внешние ресурсы
См. [RESOURCES.md](RESOURCES.md) для списка качественных видеокурсов, книг и платформ.

**Рекомендации:**
- **MIT Missing Semester:** [missing.csail.mit.edu](https://missing.csail.mit.edu/)
- **Linux Journey:** [linuxjourney.com](https://linuxjourney.com/)
- **OverTheWire (Bandit):** [overthewire.org/wargames/bandit](https://overthewire.org/wargames/bandit/)

---

## 🎯 Чек-лист готовности

Перед началом убедитесь:

- [ ] Ubuntu 20.04+ установлен (native / WSL2 / VM)
- [ ] Терминал открывается и работает
- [ ] `git`, `curl`, `vim`/`nano` установлены
- [ ] Репозиторий `kernel-shadows` склонирован
- [ ] Episode 01 директория найдена и открыта
- [ ] `README.md` прочитан (интегрированное руководство)
- [ ] Готовы к первой миссии!

---

## 🚀 Быстрый старт (для опытных)

Если вы уже знакомы с Linux:

```bash
# 1. Клонировать репозиторий
git clone https://github.com/gfazzz/kernel-shadows.git
cd kernel-shadows

# 2. Перейти к первой серии
cd season-01-shell-foundations/s01e01-terminal-awakening

# 3. Прочитать руководство и ТЗ
less README.md && cat mission.md

# 4. Взять каркас и выполнить задание
cp starter/whereami.sh ./whereami.sh   # допишите TODO по README

# 5. Проверить решение (воспроизводимый тест, без root)
bash tests/test.sh

# 6. Проверить решение
cd tests && ./test.sh
```

**Время прохождения Episode 01:** 3-4 часа (первый раз), 1-2 часа (с опытом).

---

## 💡 Советы для новичков

### 1. Не бойтесь ошибок
Linux прощает. Если что-то сломалось — можно починить. Если сломалось всё — можно переустановить.

### 2. Читайте ошибки
Сообщения об ошибках — это подсказки. Читайте их внимательно. Гуглите текст ошибки.

### 3. Используйте `man`
```bash
man ls      # Документация по команде ls
man bash    # Документация по bash
man man     # Документация по man (мета!)
```

Выход из man: клавиша `q`.

### 4. Автодополнение — ваш друг
Нажмите `Tab` для автодополнения:
```bash
cd sea<Tab>  # Автоматически дополнится до season-01-shell-foundations/
```

### 5. История команд
```bash
history          # Показать последние команды
!!               # Повторить последнюю команду
!123             # Повторить команду №123 из истории
Ctrl+R           # Поиск по истории команд (начните вводить)
```

### 6. Создавайте заметки
```bash
# Создайте файл для заметок
nano ~/NOTES.md
# Записывайте команды, которые изучили
```

### 7. Делайте снимки (Snapshots)
Если используете VM — делайте snapshot перед экспериментами. Можно будет откатиться.

### 8. Не торопитесь
Курс рассчитан на 120-160 часов. Это нормально. Качество > скорость.

---

## 🌟 Философия обучения

### Практика > Теория
80% курса — практика. 20% — теория. Лучше сделать и ошибиться, чем читать и забыть.

### Ошибки — часть процесса
Каждый сисадмин хотя бы раз удалял не то. Каждый программист хотя бы раз ломал продакшен. Ошибки — это опыт.

### Автоматизация — философия
Если делаете что-то дважды — автоматизируйте. Это не лень. Это эффективность.

### Логи не врут
Правда в логах. Люди забывают, врут, ошибаются. Логи — нет.

---

<div align="center">

## ✅ Готовы?

**Добро пожаловать в KERNEL SHADOWS.**

Вы — **Макс Соколов**, системный администратор из Новосибирска.
**Виктор Петров** поручил вам критическую миссию.
**LILITH** — ваш AI-проводник в тенях.

**Миссия началась.**

---

**"Я LILITH. Твой проводник в тенях. Покажи, на что ты способен."**

[⬆ Наверх](#kernel-shadows-с-чего-начать)

</div>

