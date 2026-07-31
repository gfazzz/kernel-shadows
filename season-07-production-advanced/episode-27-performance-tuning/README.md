# 🚀 EPISODE 27: PERFORMANCE TUNING

**KERNEL SHADOWS: Season 7 - Production & Advanced Topics**

```
███████╗██████╗ ██╗███████╗ ██████╗ ██████╗ ███████╗    ██████╗ ███████╗
██╔════╝██╔══██╗██║██╔════╝██╔═══██╗██╔══██╗██╔════╝    ╚════██╗╚════██║
█████╗  ██████╔╝██║███████╗██║   ██║██║  ██║█████╗       █████╔╝    ██╔╝
██╔══╝  ██╔═══╝ ██║╚════██║██║   ██║██║  ██║██╔══╝      ██╔═══╝    ██╔╝
███████╗██║     ██║███████║╚██████╔╝██████╔╝███████╗    ███████╗   ██║
╚══════╝╚═╝     ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚══════╝   ╚═╝
```

> **"Milliseconds matter. Every CPU cycle counts. Performance is not magic — it's measurement."**
> — Ólafur Þórsson, Performance Engineer

---

## 📋 МЕТАДАННЫЕ ЭПИЗОДА

| Параметр | Значение |
|----------|----------|
| **Тип эпизода** | Type A (Bash Automation) |
| **Сложность** | ⭐⭐⭐⭐☆ (4/5) |
| **Время прохождения** | 5-6 часов |
| **Локация** | Рейкьявик, Исландия 🇮🇸 |
| **День операции** | День 53 из 60 |
| **До финала** | 7 дней |
| **Технологии** | `perf`, `sysctl`, SQL optimization, Redis, `top`, `iostat` |
| **Финальный результат** | `performance_audit.sh` — автоматизированный профайлинг |

---

## 🎬 PROLOGUE: УЗКОЕ ГОРЛЫШКО

**[22:15 UTC]** — Рейкьявик, Исландия. Data center рядом с вулканом Fagradalsfjall.

**Location:** Исландия — идеальное место для серверов:
- ❄️ **Холодный климат** → бесплатное охлаждение
- ⚡ **Геотермальная энергия** → дешевое электричество (100% renewable)
- 🌐 **Подводные кабели** → связь с Европой и Америкой
- 🛡️ **Нейтральность** → вне юрисдикции major powers

---

### 🔥 Проблема

**Viktor (video call):** "Макс, у нас проблема. Инфраструктура тормозит."

**Viktor:** "Response time вырос с 50ms до 800ms. Database queries длятся секундами. Redis cache неэффективен. Через 7 дней — финал. Нужна оптимизация. **NOW.**"

**Viktor:** "Я отправил тебя к лучшему performance engineer в Европе."

---

### 👤 Новый персонаж: Ólafur Þórsson

**[Дверь открывается. Входит человек в черной куртке, 35 лет, татуировка руны на руке]**

**Ólafur Þórsson** (исландский акцент):
- **Роль:** Performance Engineer, ex-Google SRE
- **Специализация:** Low-latency systems, kernel tuning, database optimization
- **Background:** 10 лет оптимизировал Google Search, YouTube backend
- **Философия:** "Measure twice, optimize once. No guessing."
- **Особенность:** Говорит медленно, думает быстро

---

**Ólafur:** "Viktor called me. Your infrastructure — slow. My job — make it fast."

**Ólafur:** "Performance optimization — not art. It's **science**."

**Ólafur:** "Step 1: **Measure.** Find bottleneck."

**Ólafur:** "Step 2: **Profile.** Understand problem."

**Ólafur:** "Step 3: **Optimize.** Fix root cause."

**Ólafur:** "Step 4: **Measure again.** Validate improvement."

**Ólafur:** "Never guess. Always measure. **Data wins arguments.**"

---

**Max:** "С чего начнём?"

**Ólafur:** "CPU? Memory? Disk? Network? You tell me."

**Max:** "Не знаю..."

**Ólafur:** "Exactly. That's why we measure. Follow me."

---

**LILITH (активирована):** "Ólafur — хороший. Я работала с Google SRE. Он научил меня: performance — это не 'сделать быстрее', это 'найти узкое место и убрать его'. Слушай внимательно."

---

## 🎯 ЗАДАЧИ ЭПИЗОДА

К концу эпизода ты сможешь:

✅ **Профилировать систему** — CPU, memory, disk I/O, network
✅ **Тюнить ядро Linux** — `sysctl` параметры для производительности
✅ **Оптимизировать базу данных** — медленные запросы, индексы, EXPLAIN
✅ **Настроить кэширование** — Redis стратегии, eviction policies
✅ **Автоматизировать аудит** — `performance_audit.sh` скрипт
✅ **Измерять улучшения** — baseline → optimization → результат

**Type A Episode:** Финал = bash скрипт, но **60% времени** на изучение инструментов Linux!

---

## 🔄 ЦИКЛ 1: ИЗМЕРЕНИЕ ПРОИЗВОДИТЕЛЬНОСТИ (12 минут)

### 🎬 Сюжет (2-3 мин)

**[Ólafur ведёт Макса в серверную комнату]**

**Ólafur:** "See these servers? They work hard. But **how** hard?"

**Ólafur:** "CPU usage 80%? Good or bad? **Depends.**"

**Ólafur:** "80% на useful work? **Good.**"

**Ólafur:** "80% на context switches, I/O wait? **Bad.**"

**Ólafur (открывает терминал):** "Tools I use every day: `top`, `htop`, `iostat`, `vmstat`, `perf`. Each shows different **dimension** of performance."

---

### 📚 Теория: Метрики производительности (5-7 мин)

#### 🎭 Метафора: Ресторан

**Представь:**
- **Сервер** = ресторан
- **CPU** = повар на кухне
- **Memory** = столы для гостей
- **Disk I/O** = доставка продуктов
- **Network** = клиенты входят/выходят

**Performance проблема:**
- **Повар стоит без дела?** → CPU idle (не хватает задач)
- **Повар завален работой?** → CPU 100% (bottleneck)
- **Нет столов для гостей?** → Memory exhausted (OOM)
- **Доставка продуктов медленная?** → Disk I/O bottleneck
- **Очередь у входа?** → Network congestion

**Задача:** Найти **узкое место** (bottleneck) — кто тормозит весь процесс?

---

#### 📊 4 главных метрики (USE Method)

**USE Method** (Brendan Gregg):
1. **U**tilization — насколько загружен ресурс? (%)
2. **S**aturation — есть ли очередь? (queue depth)
3. **E**rrors — есть ли ошибки? (error count)

Применяем ко всем ресурсам: CPU, Memory, Disk, Network.

---

#### 🛠️ Инструменты профилирования

**1. `top` / `htop` — CPU и Memory в реальном времени**

```bash
top
# Или более удобный:
htop
```

**Что смотреть:**
```
top - 22:30:45 up 10 days,  3:14,  2 users,  load average: 4.52, 3.81, 2.90
Tasks: 287 total,   3 running, 284 sleeping,   0 stopped,   0 zombie
%Cpu(s): 45.2 us, 15.3 sy,  0.0 ni, 35.1 id,  3.2 wa,  0.0 hi,  1.2 si
MiB Mem :  32144.3 total,   1245.7 free,  28934.2 used,   1964.4 buff/cache
```

**Расшифровка CPU:**
- **us (user):** Время в user-space (приложения)
- **sy (system):** Время в kernel-space (системные вызовы)
- **id (idle):** Простой (свободно)
- **wa (iowait):** **КРИТИЧНО!** Ждём I/O (диск/сеть)
- **si/hi:** Обработка прерываний

**⚠️ Красные флаги:**
- `wa > 10%` → **Disk I/O bottleneck!**
- `load average > CPU cores` → **System overloaded!**
- `zombies > 0` → **Процессы не умирают!**

---

**2. `iostat` — Disk I/O статистика**

```bash
iostat -x 1 5  # Каждую секунду, 5 раз
```

**Вывод:**
```
Device   r/s   w/s  rMB/s  wMB/s  %util
sda    120.5  85.2   15.2    8.4   95.2
```

**Что смотреть:**
- **%util > 80%** → Диск на пределе!
- **await > 20ms** → Высокая латентность
- **r/s + w/s** → Количество операций в секунду

---

**3. `vmstat` — Virtual Memory статистика**

```bash
vmstat 1 10  # Каждую секунду, 10 раз
```

**Вывод:**
```
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 4  2      0 1245760 102400 1964416  0    0   150   420 5200 8400 45 15 35  3  0
```

**Критичные столбцы:**
- **r (runnable):** Процессы ждут CPU → если > cores, CPU bottleneck
- **b (blocked):** Процессы ждут I/O → если > 0, I/O bottleneck
- **si/so (swap in/out):** **КРИТИЧНО!** Если > 0 → Memory exhausted, используется swap (медленно!)
- **wa (iowait):** Ждём I/O

---

**4. `perf` — Linux Performance Profiler**

```bash
# Профилировать CPU usage (10 секунд)
sudo perf top

# Профилировать конкретный процесс
sudo perf record -p <PID> -g -- sleep 10
sudo perf report
```

**Зачем:**
- Показывает **где** тратится CPU (функции, системные вызовы)
- Flame graphs — визуализация CPU usage
- **Самый мощный инструмент** для глубокого анализа

---

#### 🎓 Стратегия диагностики

```
┌─────────────────────────────────────┐
│  START: Система медленная           │
└───────────┬─────────────────────────┘
            │
            ▼
   ┌────────────────────┐
   │  1. top / htop     │ → Check load average, CPU, memory
   └────────┬───────────┘
            │
            ▼
   ┌────────────────────┐
   │  2. vmstat         │ → Check iowait, swap, blocked procs
   └────────┬───────────┘
            │
            ▼
   High iowait? ──YES──▶ ┌──────────────┐
   │                      │  3. iostat   │ → Find slow disk
   NO                     └──────────────┘
   │
   ▼
   ┌────────────────────┐
   │  4. perf top       │ → Find CPU-hungry functions
   └────────────────────┘
```

---

**Ólafur:** "Always start with `top`. Then drill down. Don't jump to conclusions. **Measure first.**"

**LILITH:** "Ólafur прав. Я видела сотни случаев когда админы 'оптимизировали' не то. Результат: стало хуже. **Data-driven decisions only.**"

---

### 💻 Практика: Профилирование системы (3-5 мин)

**Задание:** Найди bottleneck на сервере.

```bash
# 1. Check load average
uptime

# 2. Check CPU/Memory
top
# Press 'q' to quit

# 3. Check I/O wait
vmstat 1 5

# 4. Check disk usage
iostat -x 1 3

# 5. Check network
sar -n DEV 1 3  # Если установлен sysstat
```

**Вопросы для анализа:**
1. Какой load average? Больше чем CPU cores?
2. Сколько процентов iowait?
3. Какой %util на дисках?

---

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Сервер тормозит. `top` показывает: CPU idle 70%, memory free 50%, но load average 8.0 (4 cores). **В чём проблема?**"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **I/O bottleneck** (скорее всего диск).

**Почему:**
- CPU idle 70% → CPU не загружен
- Memory free 50% → Памяти достаточно
- **Load average 8.0 на 4 cores** → 8 процессов ждут ресурс!

**Load average включает:**
1. Процессы в очереди на CPU (runnable)
2. **Процессы ждут I/O** (blocked) ← вот оно!

**Высокий load + низкий CPU usage** = процессы ждут диск/сеть.

**Проверка:**
```bash
vmstat 1 5
# Смотри столбец 'b' (blocked) — если > 0, процессы ждут I/O
# Смотри 'wa' (iowait) — если > 10%, диск тормозит
```

**Вывод:** Load average — НЕ только CPU! Это "процессы ждут ресурс" (любой: CPU, I/O, locks).

</details>

---

## 🔄 ЦИКЛ 2: KERNEL TUNING (12 минут)

### 🎬 Сюжет (2-3 мин)

**Ólafur:** "Your measurements done. Good. Now — optimization."

**Ólafur:** "Linux kernel — powerful. But default settings? **Generic.** Not optimized for your workload."

**Ólafur:** "Web server needs different settings than database server. High-latency network? Different tuning."

**Ólafur:** "Tool: `sysctl`. Kernel parameters. Change at runtime. No reboot."

---

### 📚 Теория: sysctl параметры (5-7 мин)

#### 🎭 Метафора: Настройки автомобиля

**Представь:**
- **Kernel** = двигатель автомобиля
- **sysctl** = настройки (suspension, fuel mixture, turbo boost)
- **Гоночная трасса?** → жёсткая подвеска, максимальная мощность
- **Городская езда?** → мягкая подвеска, экономия топлива

**Linux kernel** = универсальный. Настрой под свою задачу!

---

#### 📋 sysctl — управление параметрами ядра

**Просмотр параметров:**
```bash
# Все параметры
sysctl -a

# Конкретный параметр
sysctl net.ipv4.tcp_fin_timeout
```

**Изменение (временно, до перезагрузки):**
```bash
sudo sysctl -w net.ipv4.tcp_fin_timeout=30
```

**Изменение (постоянно):**
```bash
# Добавить в /etc/sysctl.conf или /etc/sysctl.d/99-custom.conf
echo "net.ipv4.tcp_fin_timeout=30" | sudo tee -a /etc/sysctl.d/99-performance.conf

# Применить
sudo sysctl -p /etc/sysctl.d/99-performance.conf
```

---

#### 🚀 Критичные параметры для производительности

**1. Network Performance (Web Servers)**

```bash
# TCP buffer sizes (для high-throughput)
net.core.rmem_max=134217728           # 128MB max receive buffer
net.core.wmem_max=134217728           # 128MB max send buffer
net.ipv4.tcp_rmem=4096 87380 67108864 # TCP read buffer (min default max)
net.ipv4.tcp_wmem=4096 65536 67108864 # TCP write buffer

# TCP connection handling
net.ipv4.tcp_fin_timeout=30           # Reduce TIME_WAIT (default 60s)
net.ipv4.tcp_tw_reuse=1               # Reuse TIME_WAIT sockets
net.ipv4.tcp_max_syn_backlog=8192     # SYN queue size (DDoS protection)
net.core.somaxconn=4096               # Max connections queue

# Connection tracking (firewall)
net.netfilter.nf_conntrack_max=1048576 # Max tracked connections
```

**Зачем:**
- **rmem/wmem:** Больше буферы = меньше network latency (особенно для long-distance)
- **tcp_fin_timeout:** Сокращает время удержания закрытых соединений → больше доступных сокетов
- **somaxconn:** Увеличивает очередь подключений → меньше refused connections

---

**2. File System & Disk I/O**

```bash
# Dirty pages (данные ожидающие записи на диск)
vm.dirty_ratio=10              # При 10% RAM начать блокировать запись
vm.dirty_background_ratio=5    # При 5% RAM начать фоновую запись
vm.swappiness=10               # Снизить использование swap (default 60)

# File handles
fs.file-max=2097152            # Max открытых файлов (системное)
```

**Зачем:**
- **dirty_ratio:** Контролирует когда kernel flush данные на диск (баланс memory vs latency)
- **swappiness:** Низкое значение = kernel предпочитает использовать RAM, не swap (для databases критично!)
- **file-max:** Увеличивает лимит открытых файлов (для high-connection servers)

---

**3. Security vs Performance Trade-offs**

```bash
# Disable IP forwarding (если не роутер)
net.ipv4.ip_forward=0

# SYN cookies (защита от SYN flood, но небольшой overhead)
net.ipv4.tcp_syncookies=1

# TCP timestamps (для защиты, но +12 bytes на packet)
net.ipv4.tcp_timestamps=0  # Отключить для микро-оптимизации
```

---

**4. Real-time & Low-latency (Advanced)**

```bash
# Kernel preemption (для real-time)
kernel.sched_rt_runtime_us=950000  # 95% CPU для real-time tasks

# Huge pages (для databases)
vm.nr_hugepages=1024  # Выделить 1024 huge pages (2MB каждая)
```

---

#### ⚠️ Предупреждения

**Ólafur:** "**Never blindly copy sysctl settings!** Every system different."

**Опасности:**
- ❌ Неправильные настройки могут **ухудшить** производительность
- ❌ Некоторые параметры требуют много памяти (можно исчерпать RAM)
- ❌ Security trade-offs (производительность vs безопасность)

**Правило:**
1. **Измерить baseline** (до изменений)
2. **Изменить один параметр**
3. **Измерить результат**
4. **Если хуже — откатить!**

**LILITH:** "Я видела как админ скопировал 'performance tuning guide' из интернета. Сервер стал медленнее на 30%. Он не понял что guide был для database server, а у него web server. **Context matters.**"

---

### 💻 Практика: Тюнинг TCP параметров (3-5 мин)

**Задание:** Оптимизировать TCP для web server (высокие connections).

```bash
# 1. Проверить текущие значения
sysctl net.ipv4.tcp_fin_timeout
sysctl net.core.somaxconn

# 2. Создать конфиг
sudo tee /etc/sysctl.d/99-web-performance.conf << 'EOF'
# Web Server TCP Optimization
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_tw_reuse=1
net.core.somaxconn=4096
net.ipv4.tcp_max_syn_backlog=8192
EOF

# 3. Применить
sudo sysctl -p /etc/sysctl.d/99-web-performance.conf

# 4. Проверить применились ли
sysctl net.ipv4.tcp_fin_timeout
```

**Подсказка:** Проверь `dmesg` после применения — там могут быть warnings о несовместимых значениях.

---

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "У тебя database server с 64GB RAM. Что случится если установить `vm.swappiness=60` (default)?

a) Ничего, это нормально
b) Database будет использовать swap, станет медленнее
c) Система упадёт"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **b) Database будет использовать swap, станет медленнее**

**Почему:**
- `vm.swappiness=60` → kernel агрессивно перемещает данные в swap (даже если RAM свободна!)
- **Database = hot data in memory** (индексы, кэши)
- Если swap используется → database читает с диска (1000x медленнее!)

**Результат:**
- Queries 10ms → 1000ms (100x медленнее!)
- "Disk thrashing" — постоянная swap активность

**Решение:**
```bash
vm.swappiness=1  # Почти не использовать swap (только emergency)
# Или даже 0 (но тогда OOM killer может убить процесс)
```

**Для databases КРИТИЧНО:** держи hot data в RAM, **НЕ в swap!**

**LILITH:** "Я видела production database с swappiness=60. Queries тормозили 10 секунд. Admin изменил на swappiness=1. Queries вернулись к 50ms. **One parameter, 200x improvement.**"

</details>

---

## 🔄 ЦИКЛ 3: DATABASE OPTIMIZATION (15 минут)

### 🎬 Сюжет (2-3 мин)

**[Ólafur открывает Grafana dashboard — response time график]**

**Ólafur:** "Look. Database queries — 95th percentile — 2 seconds. **Unacceptable.**"

**Ólafur:** "Users wait 2 seconds per page. They leave. Revenue lost."

**Max:** "Можем добавить больше RAM?"

**Ólafur (качает головой):** "Hardware — expensive. Optimization — free. Find slow queries first."

**Ólafur:** "Tools: `EXPLAIN`, slow query log, indexes. **Make database work smarter, not harder.**"

---

### 📚 Теория: SQL Optimization (7-10 мин)

#### 🎭 Метафора: Библиотека

**Представь:**
- **Database** = огромная библиотека (миллионы книг)
- **Query без index** = искать книгу **читая каждую полку** (linear scan) — часы!
- **Query с index** = использовать **каталог** (B-Tree index) — секунды!

**Без index:**
```
SELECT * FROM users WHERE email = 'max@example.com';
→ Database проверяет ВСЕ строки (1 миллион строк) = МЕДЛЕННО!
```

**С index:**
```
CREATE INDEX idx_users_email ON users(email);
→ Database использует B-Tree → находит за O(log n) = БЫСТРО!
```

---

#### 🔍 Инструменты диагностики

**1. Slow Query Log (MySQL / PostgreSQL)**

**MySQL:**
```bash
# Включить slow query log
sudo mysql -e "SET GLOBAL slow_query_log = 'ON';"
sudo mysql -e "SET GLOBAL long_query_time = 1;"  # Queries > 1s

# Лог: /var/log/mysql/mysql-slow.log
sudo tail -f /var/log/mysql/mysql-slow.log
```

**PostgreSQL:**
```bash
# В /etc/postgresql/*/main/postgresql.conf:
log_min_duration_statement = 1000  # Логировать queries > 1s

# Перезапустить
sudo systemctl restart postgresql

# Лог: /var/log/postgresql/postgresql-*-main.log
```

**Вывод:**
```
# Time: 2025-10-13T22:45:12.123456Z
# Query_time: 2.145321  Lock_time: 0.000123  Rows_sent: 1  Rows_examined: 1000000
SELECT * FROM orders WHERE user_id = 12345;
```

**Что смотреть:**
- **Query_time > 1s** → медленный запрос!
- **Rows_examined >> Rows_sent** → сканирует много строк, возвращает мало → нужен index!

---

**2. EXPLAIN — план выполнения запроса**

**MySQL:**
```sql
EXPLAIN SELECT * FROM orders WHERE user_id = 12345;
```

**Вывод:**
```
+----+-------------+--------+------+---------------+------+---------+------+--------+-------------+
| id | select_type | table  | type | possible_keys | key  | key_len | ref  | rows   | Extra       |
+----+-------------+--------+------+---------------+------+---------+------+--------+-------------+
|  1 | SIMPLE      | orders | ALL  | NULL          | NULL | NULL    | NULL | 100000 | Using where |
+----+-------------+--------+------+---------------+------+---------+------+--------+-------------+
```

**Красные флаги:**
- ❌ **type = ALL** → Full table scan (сканирует ВСЕ строки!)
- ❌ **key = NULL** → Index НЕ используется!
- ❌ **rows = 100000** → сканирует 100k строк

**После добавления index:**
```sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
EXPLAIN SELECT * FROM orders WHERE user_id = 12345;
```

**Вывод:**
```
+----+-------------+--------+-------+----------------------+----------------------+---------+-------+------+-------+
| id | select_type | table  | type  | possible_keys        | key                  | key_len | ref   | rows | Extra |
+----+-------------+--------+-------+----------------------+----------------------+---------+-------+------+-------+
|  1 | SIMPLE      | orders | ref   | idx_orders_user_id   | idx_orders_user_id   | 4       | const |  10  | NULL  |
+----+-------------+--------+-------+----------------------+----------------------+---------+-------+------+-------+
```

**Зелёные флаги:**
- ✅ **type = ref** → Index lookup (быстро!)
- ✅ **key = idx_orders_user_id** → Index используется!
- ✅ **rows = 10** → сканирует только 10 строк (вместо 100k!)

**Результат:** Query 2000ms → 5ms (**400x faster!**)

---

#### 📋 Типичные проблемы и решения

**Проблема 1: Missing Index**

```sql
-- МЕДЛЕННО (full scan):
SELECT * FROM users WHERE email = 'max@example.com';

-- РЕШЕНИЕ: Добавить index
CREATE INDEX idx_users_email ON users(email);
```

---

**Проблема 2: N+1 Query Problem**

```python
# МЕДЛЕННО: 1 query + N queries (для каждого user)
users = db.query("SELECT * FROM users LIMIT 100")
for user in users:
    orders = db.query(f"SELECT * FROM orders WHERE user_id = {user.id}")
    # 1 + 100 queries = 101 queries!
```

**РЕШЕНИЕ: JOIN или bulk fetch**
```sql
-- 1 query вместо 101:
SELECT users.*, orders.*
FROM users
LEFT JOIN orders ON users.id = orders.user_id
WHERE users.id IN (1, 2, 3, ..., 100);
```

---

**Проблема 3: SELECT \***

```sql
-- МЕДЛЕННО: забирает все столбцы (включая BLOB, TEXT)
SELECT * FROM users WHERE id = 123;

-- БЫСТРО: забирает только нужные столбцы
SELECT id, name, email FROM users WHERE id = 123;
```

**Почему:**
- Меньше data transfer (network latency)
- Index-only scan (если все столбцы в index, не читает таблицу!)

---

**Проблема 4: Отсутствие LIMIT**

```sql
-- МЕДЛЕННО: возвращает миллион строк
SELECT * FROM logs ORDER BY created_at DESC;

-- БЫСТРО: возвращает только 100
SELECT * FROM logs ORDER BY created_at DESC LIMIT 100;
```

---

#### 🎯 Monitoring: Query Performance

**MySQL:**
```sql
-- Статистика queries
SELECT schema_name,
       ROUND(SUM(count_star)/1000000, 2) AS queries_millions
FROM performance_schema.events_statements_summary_by_digest
GROUP BY schema_name;

-- Топ медленных queries
SELECT SUBSTRING(digest_text, 1, 80) AS query,
       count_star AS exec_count,
       ROUND(avg_timer_wait/1000000000, 2) AS avg_ms
FROM performance_schema.events_statements_summary_by_digest
ORDER BY avg_timer_wait DESC
LIMIT 10;
```

**PostgreSQL:**
```sql
-- Включить pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Топ медленных queries
SELECT substring(query, 1, 80) AS query,
       calls,
       round(total_time::numeric / calls, 2) AS avg_ms
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

---

**Ólafur:** "Database optimization — biggest performance wins. One index can make query 1000x faster. **Measure, explain, index.**"

**LILITH:** "Я помню case: startup добавил 3 индекса. Response time: 5 секунд → 50ms. **100x improvement, zero hardware cost.** Database optimization — ROI champion."

---

### 💻 Практика: Оптимизация SQL (3-5 мин)

**Задание:** Найди и исправь медленный запрос.

**Сценарий:** У тебя таблица `orders` (1 миллион строк). Запрос медленный:

```sql
SELECT * FROM orders WHERE customer_email = 'max@example.com';
```

**Шаги:**

```bash
# 1. Запустить тестовую базу (Docker)
docker run -d --name test-db \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=testdb \
  -p 3306:3306 \
  mysql:8.0

# 2. Подключиться
mysql -h 127.0.0.1 -u root -proot testdb

# 3. Создать тестовую таблицу
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_email VARCHAR(255),
    amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# 4. Вставить тестовые данные (100k строк)
-- См. artifacts/generate_test_data.sql

# 5. Измерить без index
EXPLAIN SELECT * FROM orders WHERE customer_email = 'test@example.com';
-- Смотри: type = ALL, rows = 100000 (full scan!)

# 6. Добавить index
CREATE INDEX idx_customer_email ON orders(customer_email);

# 7. Измерить с index
EXPLAIN SELECT * FROM orders WHERE customer_email = 'test@example.com';
-- Смотри: type = ref, rows = ~10 (index lookup!)
```

**Проверка:**
```sql
-- Сравни query time
SELECT BENCHMARK(1000, (SELECT * FROM orders WHERE customer_email = 'test@example.com'));
```

---

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Query медленный. `EXPLAIN` показывает `type = ALL`, `rows = 1000000`. Что делать **СНАЧАЛА**?

a) Добавить RAM на сервер
b) Добавить index на WHERE столбец
c) Переписать query на JOIN
d) Включить query cache"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **b) Добавить index на WHERE столбец**

**Почему:**
- `type = ALL` + `rows = 1000000` → **Full table scan!** (сканирует ВСЕ строки)
- **Root cause:** Нет index на столбец в WHERE clause
- **Решение:** Index → превращает O(n) в O(log n)

**Почему НЕ другие:**
- ❌ **a) RAM:** Не поможет — проблема не в памяти, а в отсутствии index
- ❌ **c) JOIN:** Query может быть правильным, просто нужен index
- ❌ **d) Query cache:** Кэш помогает только для повторяющихся queries, не решает root cause

**Правило:** `type = ALL` → **немедленно добавь index!**

**Пример:**
```sql
-- Query:
SELECT * FROM orders WHERE status = 'pending';

-- EXPLAIN показывает type = ALL → добавь index:
CREATE INDEX idx_orders_status ON orders(status);

-- Теперь type = ref → быстро!
```

</details>

---

## 🔄 ЦИКЛ 4: CACHING STRATEGIES (12 минут)

### 🎬 Сюжет (2-3 мин)

**Ólafur:** "Database faster now. Good. But still — database call = 10ms minimum. Network + query + response."

**Ólafur:** "Can we do better? **Yes. Cache.**"

**Ólafur:** "Redis — in-memory cache. 0.5ms response time. **20x faster than database.**"

**Max:** "Но кэш может устареть (stale data)?"

**Ólafur:** "Exactly. Caching — trade-off: **speed vs freshness**. Choose strategy wisely."

---

### 📚 Теория: Redis Caching (5-7 мин)

#### 🎭 Метафора: Памятка на холодильнике

**Представь:**
- **Database** = архив в подвале (далеко, медленно)
- **Cache (Redis)** = памятка на холодильнике (близко, быстро)

**Workflow:**
1. Нужна информация → проверь памятку (cache)
2. Есть? → используй (cache hit)
3. Нет? → спустись в подвал (database), принеси, **запиши на памятку** (cache set)

**Проблема:** Памятка устаревает. **Решение:** Стратегия инвалидации.

---

#### 🔧 Redis Caching Patterns

**1. Cache-Aside (Lazy Loading)**

```python
# Псевдокод
def get_user(user_id):
    # 1. Проверь cache
    cached = redis.get(f"user:{user_id}")
    if cached:
        return cached  # Cache hit!

    # 2. Cache miss → fetch from database
    user = db.query(f"SELECT * FROM users WHERE id = {user_id}")

    # 3. Store in cache (TTL = 3600s)
    redis.setex(f"user:{user_id}", 3600, user)

    return user
```

**Плюсы:**
- ✅ Простая реализация
- ✅ Кэшируются только нужные данные (lazy)

**Минусы:**
- ❌ Cache miss = latency spike (first request медленный)
- ❌ Stale data (если database обновился, cache не знает)

---

**2. Write-Through Cache**

```python
def update_user(user_id, data):
    # 1. Обнови database
    db.update(f"UPDATE users SET ... WHERE id = {user_id}", data)

    # 2. Обнови cache
    redis.setex(f"user:{user_id}", 3600, data)
```

**Плюсы:**
- ✅ Cache всегда fresh (синхронизирован с database)

**Минусы:**
- ❌ Каждый write = 2 операции (database + cache)
- ❌ Write latency выше

---

**3. Cache Invalidation (Delete on Write)**

```python
def update_user(user_id, data):
    # 1. Обнови database
    db.update(f"UPDATE users SET ... WHERE id = {user_id}", data)

    # 2. Удали из cache (следующий read обновит)
    redis.delete(f"user:{user_id}")
```

**Плюсы:**
- ✅ Простая реализация
- ✅ Cache всегда eventually consistent

**Минусы:**
- ❌ Первый read после update = cache miss

---

#### ⏰ TTL (Time To Live) Strategy

**Проблема:** Данные в cache устаревают.

**Решение:** TTL — автоматическое удаление через N секунд.

```bash
# Redis: Set с TTL
redis-cli SET user:123 '{"name":"Max"}' EX 3600  # 1 час

# Python
redis.setex("user:123", 3600, '{"name":"Max"}')
```

**Выбор TTL:**
- **Часто меняющиеся данные** (курс валют): TTL = 60 секунд
- **Редко меняющиеся** (профиль пользователя): TTL = 3600 секунд (1 час)
- **Почти статичные** (конфигурация): TTL = 86400 секунд (1 день)

---

#### 🗑️ Eviction Policies (когда Redis заполнен)

**Когда память заполнена — что удалять?**

```bash
# В /etc/redis/redis.conf:
maxmemory 2gb
maxmemory-policy allkeys-lru
```

**Политики:**
- **allkeys-lru:** Удалить least recently used (LRU) — **рекомендуется для cache**
- **volatile-lru:** Удалить LRU среди ключей с TTL
- **allkeys-lfu:** Удалить least frequently used (LFU)
- **volatile-ttl:** Удалить ключи с самым коротким TTL
- **noeviction:** НЕ удалять, вернуть ошибку (для persistent data)

**Для cache:** `allkeys-lru` — самый популярный choice.

---

#### 📊 Cache Metrics

**Измерение эффективности:**

```bash
# Redis INFO
redis-cli INFO stats | grep -E 'hits|misses'

# Вывод:
keyspace_hits:1000000
keyspace_misses:50000
```

**Cache Hit Rate:**
```
Hit Rate = hits / (hits + misses) = 1000000 / 1050000 = 95.2%
```

**Целевой Hit Rate:**
- 🟢 **> 90%** — отлично!
- 🟡 **70-90%** — хорошо
- 🔴 **< 70%** — плохо (TTL слишком короткий? или данные редко используются повторно?)

---

**Ólafur:** "Good cache strategy: 80% database load reduction. Bad cache strategy: stale data, angry users. **Measure hit rate, tune TTL.**"

**LILITH:** "Я видела production где cache hit rate был 10%. Оказалось TTL = 10 секунд (слишком короткий). Изменили на 300 секунд → hit rate 85%. **Database load -75%.**"

---

### 💻 Практика: Настройка Redis Cache (3-5 мин)

**Задание:** Настроить Redis для caching user profiles.

```bash
# 1. Установить Redis (если нет)
sudo apt install redis-server -y

# 2. Настроить eviction policy
sudo tee -a /etc/redis/redis.conf << 'EOF'
maxmemory 512mb
maxmemory-policy allkeys-lru
EOF

# 3. Перезапустить Redis
sudo systemctl restart redis-server

# 4. Тест: Set с TTL
redis-cli SET user:123 '{"name":"Max","email":"max@example.com"}' EX 300

# 5. Проверить TTL
redis-cli TTL user:123
# Output: 300 (секунд до expiration)

# 6. Через 5 минут проверить снова
# redis-cli GET user:123
# Output: (nil) — ключ удалился автоматически!

# 7. Проверить cache hit rate
redis-cli INFO stats | grep -E 'keyspace_hits|keyspace_misses'
```

---

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Redis memory заполнена. Приходит новый SET. `maxmemory-policy = noeviction`. Что произойдёт?

a) Удалится самый старый ключ
b) Удалится LRU ключ
c) Вернётся ошибка
d) Redis упадёт"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **c) Вернётся ошибка**

**Почему:**
- `noeviction` = **НЕ удалять данные** при заполнении памяти
- Redis вернёт: `(error) OOM command not allowed when used memory > 'maxmemory'`

**Когда использовать:**
- ✅ **Persistent data** (не cache!) — не хочешь потерять данные
- ❌ **Cache** — должен использовать `allkeys-lru` (автоматически освобождает место)

**Пример ошибки:**
```bash
redis-cli SET key1 value1
# (error) OOM command not allowed when used memory > 'maxmemory'.
```

**Решение:**
1. Увеличить `maxmemory`
2. Или изменить на `allkeys-lru` (для cache)

**Правило:** Cache = `allkeys-lru`, Persistent data = `noeviction` (но тогда мониторь memory!)

</details>

---

## 🔄 ЦИКЛ 5: LOAD TESTING (10 минут)

### 🎬 Сюжет (2-3 мин)

**Ólafur:** "Optimizations done. Now — **validate**. Did it actually improve?"

**Ólafur:** "Only one way to know: **load test**. Simulate production traffic. Measure before/after."

**Max:** "Какие инструменты?"

**Ólafur:** "Apache Bench (`ab`), `hey`, `wrk`, Locust. I prefer `ab` — simple, fast."

---

### 📚 Теория: Load Testing (краткая версия)

**Метрики:**
- **RPS (Requests Per Second)** — throughput
- **Latency** — p50, p95, p99
- **Error rate** — % failed requests

**Инструменты:**

```bash
# Apache Bench (simple)
ab -n 10000 -c 100 http://localhost/api/users
# -n = total requests
# -c = concurrent requests

# hey (Go-based, более modern)
hey -n 10000 -c 100 http://localhost/api/users

# wrk (advanced, Lua scripting)
wrk -t4 -c100 -d30s http://localhost/api/users
```

---

### 💻 Практика: Benchmark Before/After (краткая)

```bash
# BEFORE optimization
ab -n 1000 -c 50 http://localhost/api/users > before.txt

# Apply optimizations (indexes, cache, sysctl)

# AFTER optimization
ab -n 1000 -c 50 http://localhost/api/users > after.txt

# Compare
grep "Requests per second" before.txt after.txt
grep "Time per request" before.txt after.txt
```

---

## 🔄 ЦИКЛ 6: MONITORING INTEGRATION (10 минут)

### 📚 Теория: Continuous Performance Monitoring (краткая)

**После оптимизации — мониторинг критичен!**

**Метрики для алертов:**
```yaml
# Prometheus alert rules
- alert: HighResponseTime
  expr: histogram_quantile(0.95, http_request_duration_seconds) > 1.0
  for: 5m
  annotations:
    summary: "P95 latency > 1s"

- alert: HighDatabaseLatency
  expr: mysql_global_status_queries > 1000
  annotations:
    summary: "Database overloaded"
```

**(Подробнее в Episode 26 — Monitoring)**

---

## 🔄 ЦИКЛ 7: TROUBLESHOOTING BOTTLENECKS (10 минут)

### 📚 Теория: Common Performance Killers (краткая)

**1. Thundering Herd (Cache Stampede)**
- Проблема: Cache key expires → 1000 requests одновременно запрашивают database
- Решение: Lock, probabilistic early expiration

**2. Database Connection Pool Exhaustion**
- Проблема: Слишком мало connections → requests ждут
- Решение: Увеличить pool size (но не слишком!)

**3. Memory Leak**
- Проблема: Приложение не освобождает память → OOM
- Решение: Profiling (`valgrind`, `heaptrack`)

**4. DNS Resolution Latency**
- Проблема: Каждый request = DNS lookup
- Решение: Connection pooling, keep-alive

---

## 🔄 ЦИКЛ 8: FINAL PERFORMANCE AUDIT SCRIPT (12 минут)

### 🎬 Сюжет (2-3 мин)

**Ólafur:** "Time to automate. Create script — performance audit. Run anytime. Checks everything."

---

### 📚 Теория: Audit Script Structure (краткая)

**Скрипт должен проверять:**
1. ✅ System load (CPU, memory, disk)
2. ✅ Network performance (latency, bandwidth)
3. ✅ Database slow queries
4. ✅ Cache hit rate
5. ✅ sysctl settings
6. ✅ Generate report

---

### 💻 Практика: Создать `performance_audit.sh`

**См. `starter/performance_audit.sh` для шаблона.**

**Требования:**
- Проверить все метрики
- Вывести цветной отчёт (🟢/🟡/🔴)
- Сохранить в файл с timestamp
- Сравнить с baseline (опционально)

**Прогрессивные подсказки:**

<details>
<summary>🔍 Подсказка 1: Структура скрипта</summary>

```bash
#!/bin/bash
# performance_audit.sh

# Functions:
check_cpu() { ... }
check_memory() { ... }
check_disk_io() { ... }
check_database() { ... }
check_cache() { ... }
generate_report() { ... }

# Main
main() {
    echo "=== PERFORMANCE AUDIT ==="
    check_cpu
    check_memory
    # ...
    generate_report
}

main "$@"
```

</details>

<details>
<summary>🔍 Подсказка 2: Проверка CPU</summary>

```bash
check_cpu() {
    load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    cores=$(nproc)

    if (( $(echo "$load > $cores" | bc -l) )); then
        echo "🔴 CPU overloaded: $load (cores: $cores)"
    else
        echo "🟢 CPU OK: $load"
    fi
}
```

</details>

<details>
<summary>🔍 Подсказка 3: Проверка Redis Hit Rate</summary>

```bash
check_cache() {
    hits=$(redis-cli INFO stats | grep keyspace_hits | cut -d: -f2 | tr -d '\r')
    misses=$(redis-cli INFO stats | grep keyspace_misses | cut -d: -f2 | tr -d '\r')

    total=$((hits + misses))
    if [ $total -gt 0 ]; then
        hit_rate=$(echo "scale=2; $hits * 100 / $total" | bc)

        if (( $(echo "$hit_rate > 90" | bc -l) )); then
            echo "🟢 Cache hit rate: ${hit_rate}%"
        elif (( $(echo "$hit_rate > 70" | bc -l) )); then
            echo "🟡 Cache hit rate: ${hit_rate}% (можно улучшить)"
        else
            echo "🔴 Cache hit rate: ${hit_rate}% (критично низкий!)"
        fi
    fi
}
```

</details>

**См. `solution/performance_audit.sh` для полного решения (НЕ смотри раньше времени!).**

---

## 📋 ПРАКТИЧЕСКИЕ ЗАДАНИЯ

### Итоговое задание: Full Performance Optimization

**Сценарий:** У тебя production-подобная система (веб-сервер + база + cache). Она медленная. **Оптимизируй.**

**Шаги:**

1. **Baseline measurement**
   ```bash
   # Измерить текущую производительность
   ab -n 1000 -c 50 http://localhost/api/test > baseline.txt
   ./performance_audit.sh > baseline_audit.txt
   ```

2. **System profiling**
   ```bash
   # CPU, memory, I/O
   top -bn1 > top_before.txt
   iostat -x 1 10 > iostat_before.txt
   vmstat 1 10 > vmstat_before.txt
   ```

3. **Apply optimizations:**
   - ✅ Kernel tuning (sysctl)
   - ✅ Database indexes (EXPLAIN → CREATE INDEX)
   - ✅ Redis caching (set TTL, eviction policy)

4. **Post-optimization measurement**
   ```bash
   ab -n 1000 -c 50 http://localhost/api/test > after.txt
   ./performance_audit.sh > after_audit.txt
   ```

5. **Generate comparison report**
   ```bash
   ./compare_results.sh baseline.txt after.txt
   ```

**Цель:**
- 🎯 Response time уменьшить на 50%+
- 🎯 RPS увеличить на 2x+
- 🎯 Cache hit rate > 85%
- 🎯 Database slow queries = 0

---

## 🎬 EPILOGUE: СКОРОСТЬ СВЕТА

**[01:30 UTC]** — 3 часа спустя.

**[Max запускает финальный benchmark]**

```bash
$ ab -n 10000 -c 100 http://localhost/api/users

Requests per second: 2,450.32 [#/sec] (mean)
Time per request: 40.81 [ms] (mean)
```

**Max:** "БЫЛО: 180 RPS, 550ms latency. СТАЛО: 2,450 RPS, 40ms latency. **13x throughput, 13x faster!**"

**Ólafur (кивает):** "Good. Now you understand: **performance is science, not magic.**"

**Ólafur:** "Measure → Profile → Optimize → Validate. Repeat."

**Max:** "Что дальше?"

**Ólafur:** "Security hardening. Episode 28. Performance without security — useless. Fast compromised server — still compromised."

**[Viktor (video call):]**

**Viktor:** "Макс, отличная работа. Infrastructure готова. Осталось 6 дней до финала."

**Viktor:** "Episode 28 — последний перед финалом. Security hardening. SELinux, auditd, fail2ban. **Lock it down.**"

**Viktor:** "После этого — Season 8. **Finale.** 72 часа. Global attack. Everything you learned."

**Max:** "Готов."

---

## ✅ ЧТО ТЫ ИЗУЧИЛ

### Инструменты:
- ✅ **Профилирование:** `top`, `htop`, `iostat`, `vmstat`, `perf`
- ✅ **Kernel tuning:** `sysctl` параметры (TCP, memory, disk)
- ✅ **Database optimization:** `EXPLAIN`, slow query log, indexes
- ✅ **Caching:** Redis strategies, TTL, eviction policies
- ✅ **Load testing:** `ab`, `hey`, benchmark before/after
- ✅ **Monitoring integration:** Prometheus alerts
- ✅ **Troubleshooting:** Common bottlenecks и их решения

### Bash Automation:
- ✅ `performance_audit.sh` — комплексный аудит системы
- ✅ Измерение baseline vs optimized
- ✅ Цветные отчёты, thresholds, alerts

**Развёрнуто:**
- Оптимизировано: CPU usage, disk I/O, database queries, cache hit rate
- Bash скрипт: автоматизированный performance audit
- Результат: 13x throughput, 13x lower latency

**Время прохождения:** 5-6 часов
**Сложность:** ⭐⭐⭐⭐☆
**Production готовность:** 85% (performance оптимизирована, осталась security)

---

## 🔗 СЛЕДУЮЩИЙ ЭПИЗОД

**Episode 28: Security Hardening**
- SELinux enforcement (Mandatory Access Control)
- auditd logging (система аудита)
- fail2ban (защита от brute-force)
- Kernel security параметры
- **Персонаж:** [TBD — Security Expert]

**День 56 операции** — 4 дня до финала

---

<div align="center">

**⚡ "Measure twice, optimize once." — Ólafur Þórsson**

**[SEASON 7: 3/4 COMPLETE]**

**[NEXT: EPISODE 28 — SECURITY HARDENING]**

</div>

