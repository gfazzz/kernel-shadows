# 📦 ARTIFACTS - EPISODE 27

Вспомогательные материалы для Episode 27: Performance Tuning.

---

## 📋 Содержимое

### 1. **SYSCTL_CHEATSHEET.md**
Шпаргалка по sysctl параметрам для оптимизации производительности.

### 2. **PERFORMANCE_TOOLS_GUIDE.md**
Руководство по инструментам профилирования (`top`, `iostat`, `vmstat`, `perf`).

### 3. **SQL_OPTIMIZATION_GUIDE.md**
Гайд по оптимизации SQL запросов (indexes, EXPLAIN, best practices).

### 4. **REDIS_CACHING_PATTERNS.md**
Паттерны кэширования с Redis (cache-aside, write-through, TTL strategies).

---

## 🚀 Использование

### Быстрая справка по командам:

```bash
# CPU profiling
top -bn1
htop
perf top

# Memory
free -h
vmstat 1 10

# Disk I/O
iostat -x 1 5
iotop

# Network
ss -tan | grep ESTAB | wc -l
sar -n DEV 1 5

# Database (MySQL)
mysql -e "SHOW PROCESSLIST;"
mysql -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';"

# Redis
redis-cli INFO stats | grep keyspace
redis-cli --stat

# sysctl
sysctl -a | grep tcp
sysctl -w net.ipv4.tcp_fin_timeout=30
```

---

## 📚 Дополнительные ресурсы

- **Brendan Gregg's Performance Tools:** http://www.brendangregg.com/linuxperf.html
- **USE Method:** Utilization, Saturation, Errors
- **RED Method:** Rate, Errors, Duration (для микросервисов)

---

**LILITH:** "Эти cheat sheets сохранят тебе часы troubleshooting. Закладки в браузере или распечатай. Профилирование — не время искать синтаксис команд в Google."

