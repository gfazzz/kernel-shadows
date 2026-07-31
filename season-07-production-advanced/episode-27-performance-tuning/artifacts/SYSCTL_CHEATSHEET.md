# 🔧 SYSCTL CHEATSHEET

**Episode 27: Performance Tuning** — Шпаргалка по kernel tuning параметрам.

---

## 📖 Основы sysctl

### Просмотр параметров

```bash
# Все параметры
sysctl -a

# Конкретный параметр
sysctl net.ipv4.tcp_fin_timeout

# Поиск по pattern
sysctl -a | grep tcp

# Из файла
cat /proc/sys/net/ipv4/tcp_fin_timeout
```

### Изменение параметров

```bash
# Временно (до перезагрузки)
sudo sysctl -w net.ipv4.tcp_fin_timeout=30

# Постоянно
echo "net.ipv4.tcp_fin_timeout=30" | sudo tee -a /etc/sysctl.d/99-performance.conf
sudo sysctl -p /etc/sysctl.d/99-performance.conf

# Или редактировать /etc/sysctl.conf
sudo nano /etc/sysctl.conf
# Добавить: net.ipv4.tcp_fin_timeout=30
sudo sysctl -p
```

---

## 🌐 NETWORK PERFORMANCE

### TCP Buffer Sizes (для high-throughput)

```bash
# Receive buffer (max 128MB)
net.core.rmem_max=134217728
net.core.rmem_default=16777216

# Send buffer (max 128MB)
net.core.wmem_max=134217728
net.core.wmem_default=16777216

# TCP-specific buffers (min default max)
net.ipv4.tcp_rmem=4096 87380 134217728
net.ipv4.tcp_wmem=4096 65536 134217728

# Применение: для серверов с высоким network throughput
# Web servers, API gateways, file servers
```

**Зачем:**
- Больше буферы → меньше round-trips → меньше latency
- Особенно важно для long-distance connections (WAN)

---

### TCP Connection Handling

```bash
# Reduce TIME_WAIT duration (default: 60s)
net.ipv4.tcp_fin_timeout=30

# Reuse TIME_WAIT sockets for new connections
net.ipv4.tcp_tw_reuse=1

# Recycle TIME_WAIT sockets (deprecated, не используй!)
# net.ipv4.tcp_tw_recycle=1  # REMOVED в Linux 4.12+

# Max SYN backlog (защита от SYN flood)
net.ipv4.tcp_max_syn_backlog=8192

# Max connection queue (listen backlog)
net.core.somaxconn=4096

# SYN cookies (защита от SYN flood, но небольшой overhead)
net.ipv4.tcp_syncookies=1
```

**Зачем:**
- `tcp_fin_timeout=30`: Освобождает сокеты быстрее → больше доступных connections
- `tcp_tw_reuse=1`: Переиспользует закрытые сокеты → высокий RPS
- `somaxconn=4096`: Увеличивает очередь подключений → меньше refused connections

**Применение:** High-traffic web servers, load balancers

---

### Connection Tracking (для firewalls)

```bash
# Max tracked connections (для iptables/nftables)
net.netfilter.nf_conntrack_max=1048576

# Conntrack table size
net.netfilter.nf_conntrack_buckets=262144

# Conntrack timeout (TCP)
net.netfilter.nf_conntrack_tcp_timeout_established=3600
```

**Зачем:**
- Увеличивает лимит отслеживаемых соединений
- Критично для firewalls, NAT gateways

---

### TCP Optimizations

```bash
# Enable TCP Fast Open (TFO)
net.ipv4.tcp_fastopen=3
# 1 = client, 2 = server, 3 = both

# TCP window scaling (для high-bandwidth networks)
net.ipv4.tcp_window_scaling=1

# TCP timestamps (для защиты, но +12 bytes overhead)
net.ipv4.tcp_timestamps=0  # Отключить для микро-оптимизации

# TCP SACK (Selective Acknowledgment)
net.ipv4.tcp_sack=1

# TCP keepalive
net.ipv4.tcp_keepalive_time=600     # 10 минут (default: 7200)
net.ipv4.tcp_keepalive_intvl=60     # Интервал проб
net.ipv4.tcp_keepalive_probes=3     # Количество проб
```

---

## 💾 MEMORY & SWAP

### Virtual Memory

```bash
# Swappiness (как агрессивно использовать swap)
vm.swappiness=1
# 0 = минимальный swap (только emergency)
# 1 = почти не использовать swap (рекомендуется для DB)
# 10 = низкий swap (хороший баланс)
# 60 = default (агрессивный swap)
# 100 = максимальный swap

# Dirty pages (данные ожидающие записи на диск)
vm.dirty_ratio=10              # При 10% RAM блокировать запись
vm.dirty_background_ratio=5    # При 5% RAM начать фоновую запись
vm.dirty_expire_centisecs=3000 # 30 секунд до flush
vm.dirty_writeback_centisecs=500 # Каждые 5 секунд проверять

# OOM (Out Of Memory) behavior
vm.overcommit_memory=1
# 0 = heuristic (default)
# 1 = always allow (может привести к OOM)
# 2 = never overcommit
```

**Рекомендации:**
- **Database servers:** `vm.swappiness=1` (держи hot data в RAM!)
- **Web servers:** `vm.swappiness=10`
- **Generic:** `vm.swappiness=60` (default)

**Зачем:**
- `swappiness=1`: Prevent swap usage → избежать disk thrashing
- `dirty_ratio`: Контроль flush на диск → баланс latency vs consistency

---

### Huge Pages (для databases)

```bash
# Transparent Huge Pages (THP)
# Проверить текущее состояние:
cat /sys/kernel/mm/transparent_hugepage/enabled
# [always] madvise never

# Отключить THP (рекомендуется для MongoDB, Redis)
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# Explicit huge pages (для Oracle, PostgreSQL)
vm.nr_hugepages=1024  # 1024 * 2MB = 2GB
vm.hugetlb_shm_group=1001  # GID группы которая может использовать
```

**Зачем:**
- Huge pages (2MB вместо 4KB) → меньше TLB misses → faster memory access
- Критично для больших databases (100GB+ memory)

---

## 📁 FILE SYSTEM & I/O

### File Handles

```bash
# Max открытых файлов (системный лимит)
fs.file-max=2097152

# Также нужно поднять ulimit для пользователя:
# В /etc/security/limits.conf:
# * soft nofile 65536
# * hard nofile 1048576
```

**Зачем:**
- Увеличивает лимит открытых файлов
- Критично для high-connection servers (web, database)

---

### I/O Scheduler

```bash
# Проверить текущий scheduler
cat /sys/block/sda/queue/scheduler
# [mq-deadline] kyber bfq none

# Изменить (для SSD/NVMe используй none или kyber)
echo none > /sys/block/sda/queue/scheduler

# Для HDD используй mq-deadline или bfq
echo mq-deadline > /sys/block/sda/queue/scheduler
```

**Рекомендации:**
- **SSD/NVMe:** `none` или `kyber` (меньше overhead)
- **HDD:** `mq-deadline` (оптимизирует seek time)

---

## 🔐 SECURITY (trade-offs с performance)

### Network Security

```bash
# Disable IP forwarding (если не роутер)
net.ipv4.ip_forward=0
net.ipv6.conf.all.forwarding=0

# SYN cookies (защита от SYN flood)
net.ipv4.tcp_syncookies=1

# Ignore ICMP redirects (security)
net.ipv4.conf.all.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0

# Ignore source-routed packets
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0

# Reverse path filtering (защита от IP spoofing)
net.ipv4.conf.all.rp_filter=1
```

---

### Kernel Security

```bash
# Kernel address space layout randomization
kernel.randomize_va_space=2

# Restrict dmesg
kernel.dmesg_restrict=1

# Restrict kernel pointers в /proc
kernel.kptr_restrict=1
```

---

## ⚡ REAL-TIME & LOW-LATENCY

### Scheduler Tuning

```bash
# Real-time task runtime (95% CPU для RT tasks)
kernel.sched_rt_runtime_us=950000

# CPU scheduling latency (для low-latency)
kernel.sched_min_granularity_ns=10000000    # 10ms
kernel.sched_wakeup_granularity_ns=15000000 # 15ms
```

**Применение:** Audio/video processing, trading systems, embedded

---

## 🎯 ГОТОВЫЕ КОНФИГУРАЦИИ

### Web Server (Nginx, Apache)

```bash
# /etc/sysctl.d/99-web-server.conf

# Network
net.core.somaxconn=4096
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_tw_reuse=1
net.core.rmem_max=16777216
net.core.wmem_max=16777216

# File handles
fs.file-max=1048576

# Memory
vm.swappiness=10
```

---

### Database Server (MySQL, PostgreSQL)

```bash
# /etc/sysctl.d/99-database.conf

# Memory (критично!)
vm.swappiness=1
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# Huge pages (для больших DB)
vm.nr_hugepages=1024

# File handles
fs.file-max=2097152

# Network
net.core.somaxconn=2048
net.ipv4.tcp_keepalive_time=300
```

---

### Redis / Memcached (Cache)

```bash
# /etc/sysctl.d/99-cache.conf

# Memory
vm.overcommit_memory=1
vm.swappiness=0

# Transparent Huge Pages (ОТКЛЮЧИТЬ для Redis!)
# echo never > /sys/kernel/mm/transparent_hugepage/enabled

# Network
net.core.somaxconn=65535
```

---

### Load Balancer / Proxy (HAProxy, Envoy)

```bash
# /etc/sysctl.d/99-load-balancer.conf

# Network (high connection count!)
net.core.somaxconn=8192
net.ipv4.tcp_max_syn_backlog=16384
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1

# Connection tracking
net.netfilter.nf_conntrack_max=1048576
net.netfilter.nf_conntrack_buckets=262144

# TCP buffers
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# File handles
fs.file-max=2097152
```

---

## ⚠️ ВАЖНЫЕ ЗАМЕЧАНИЯ

### 1. **Не копируй слепо!**
   - Каждая система уникальна
   - Неправильные настройки могут **ухудшить** производительность
   - **Измеряй до и после!**

### 2. **Тестируй изменения**
   - Изменяй **по одному параметру**
   - Измеряй результат (`ab`, `wrk`, мониторинг)
   - Если хуже — откати!

### 3. **Баланс: Performance vs Security**
   - Некоторые оптимизации снижают безопасность
   - `tcp_tw_reuse=1` — OK
   - `tcp_tw_recycle=1` — НЕ ИСПОЛЬЗУЙ (deprecated, проблемы с NAT)

### 4. **Kernel версия важна**
   - Некоторые параметры не существуют в старых версиях
   - `tcp_tw_recycle` удалён в Linux 4.12+
   - Проверяй документацию для своей версии

---

## 📊 MONITORING

### Проверка текущих значений

```bash
# Все sysctl параметры
sysctl -a > sysctl_current.txt

# Сравнить с baseline
diff sysctl_baseline.txt sysctl_current.txt

# Проверить конкретные параметры
sysctl net.ipv4.tcp_fin_timeout
sysctl net.core.somaxconn
sysctl vm.swappiness
```

### Monitoring метрики

```bash
# Connection states
ss -tan | awk '{print $1}' | sort | uniq -c

# TIME_WAIT count
ss -tan | grep TIME-WAIT | wc -l

# Memory usage
free -h
cat /proc/meminfo

# Swap usage
swapon --show
```

---

## 🔗 ПОЛЕЗНЫЕ ССЫЛКИ

- **Linux Kernel Documentation:** https://www.kernel.org/doc/Documentation/sysctl/
- **Brendan Gregg's Tuning Guide:** http://www.brendangregg.com/linuxperf.html
- **Red Hat Performance Tuning Guide:** https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/

---

**LILITH:** "Sysctl — мощный инструмент. Один параметр может дать 2x throughput. Но неправильный параметр может убить систему. **Measure, change, validate.** Всегда в таком порядке."

