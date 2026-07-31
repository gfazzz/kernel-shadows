# Episode 29 Artifacts — Инструкция по использованию

## 📁 Структура

```
artifacts/
├── logs/                    (атака логи — для анализа patterns)
├── forensics/               (результаты расследования backdoors)
├── monitoring/              (LILITH alerts, metrics)
├── compromised_servers/     (snapshots компромизированных систем)
└── README.md                (этот файл)
```

## 🎯 Как использовать artifacts

### 1. Для практики команд

**Пример: Анализ LILITH alerts**

```bash
# Показать только Critical alerts
grep "P1 CRITICAL" artifacts/monitoring/lilith_alerts.txt

# Показать timeline атаки
grep -E "08:4[5-9]|09:0" artifacts/monitoring/lilith_alerts.txt

# Подсчитать alerts по priority
echo "P1: $(grep -c 'P1 CRITICAL' artifacts/monitoring/lilith_alerts.txt)"
echo "P2: $(grep -c 'P2 HIGH' artifacts/monitoring/lilith_alerts.txt)"
echo "P3: $(grep -c 'P3 MEDIUM' artifacts/monitoring/lilith_alerts.txt)"
```

### 2. Для понимания incident timeline

**Прочитай files в порядке:**

1. `monitoring/lilith_alerts.txt` — что происходило (timeline)
2. `forensics/backdoor_analysis.txt` — как backdoors работали
3. Понимание цепочки событий помогает принимать решения

### 3. Для написания scripts

**Scripts из Episode 29 используют эти artifacts:**

```bash
# В starter/alert_triage.sh
INPUT_FILE="artifacts/monitoring/lilith_alerts.txt"

# Ваш script может читать alerts и prioritize их
grep -i "critical\|backdoor" "$INPUT_FILE"
```

## 📊 Описание каждого artifact

### monitoring/lilith_alerts.txt

**Что это:** Полный log LILITH alerts за Day 57 (06:00-18:00 UTC)

**Содержит:**
- 73 alerts total (12 P1, 9 P2, 14 P3, 38 INFO)
- Timeline DDoS атаки (08:47-09:47 UTC)
- Zero-day detection (10:15-11:00 UTC)
- Backdoor discovery (12:00-12:30 UTC)
- Marcus Weber anomaly (14:00-14:45 UTC)

**Как использовать:**
```bash
# Real-time simulation: читай alerts по времени
less artifacts/monitoring/lilith_alerts.txt

# Filter by time range
sed -n '/08:45/,/09:00/p' artifacts/monitoring/lilith_alerts.txt

# Extract только CRITICAL
awk '/P1 CRITICAL/' artifacts/monitoring/lilith_alerts.txt
```

**Учебная задача:**
- Напиши script который triage alerts по priority
- Пример в `starter/alert_triage.sh`

---

### forensics/backdoor_analysis.txt

**Что это:** Детальный forensics report от Anna Kovaleva

**Содержит:**
- Technical analysis 5 backdoors
- Timeline reconstruction (Day 43 → Day 57)
- Backdoor code (decompiled)
- C2 server details
- Supply chain attack vector
- Impact assessment
- Remediation actions

**Как использовать:**
```bash
# Читать как PDF — это reference document
less artifacts/forensics/backdoor_analysis.txt

# Извлечь ключевые данные
grep "PID" artifacts/forensics/backdoor_analysis.txt
grep "195.123.221.47" artifacts/forensics/backdoor_analysis.txt
```

**Учебная задача:**
- Понять КАК backdoors работают
- Найти indicators of compromise (IOCs)
- Применить это знание для detection scripts

**Key takeaways from this file:**
1. Backdoors были dormant 13 дней (APT patience)
2. Supply chain attack через Docker Hub
3. Using "latest" tag вместо digest = уязвимость
4. Detection за 5 минут = good response time

---

### logs/ (будут добавлены)

Планируются:
- `ddos_attack_day57.log` — network traffic patterns
- `nginx_error_zerodayexploit.log` — CVE-2025-XXXXX attempts
- `backdoor_network_connections.pcap` — C2 communication capture

**Как использовать (когда созданы):**
```bash
# Analyze DDoS patterns
grep "SYN" logs/ddos_attack_day57.log | wc -l

# Find exploit attempts
grep "CVE-2025-XXXXX" logs/nginx_error_zerodayexploit.log

# Wireshark analysis (если pcap создан)
tshark -r logs/backdoor_network_connections.pcap \
  -Y "ip.dst == 195.123.221.47"
```

---

### compromised_servers/ (будут добавлены)

Планируются:
- `moscow-app-03_snapshot.txt` — process list, network
- `zurich-db-02_processes.txt` — compromised server state

**Назначение:**
Snapshots серверов в момент compromise (для forensics practice)

---

## 🛠️ Практические задания с artifacts

### Задание 1: Alert Triage

**Цель:** Научиться prioritize alerts

```bash
# Используй starter/alert_triage.sh
# Он читает artifacts/monitoring/lilith_alerts.txt
# И сортирует по P1/P2/P3

# Твоя задача: понять логику, модифицировать script
```

### Задание 2: Backdoor Detection

**Цель:** Найти indicators of compromise

```bash
# Из backdoor_analysis.txt извлеки:
# 1. Все PIDs backdoor процессов
# 2. C2 server IP
# 3. Backdoor file locations

# Напиши script который ищет эти indicators на системе
```

**Пример:**
```bash
#!/bin/bash
# backdoor_detection.sh

# IOCs from forensics
BACKDOOR_PIDS=(8472 3291 9845 2156 7623)
C2_IP="195.123.221.47"
BACKDOOR_PATHS=(
    "/tmp/.systemd-private"
    "/usr/bin/.update"
    "/var/tmp/.cache"
)

# Check for backdoor processes
for pid in "${BACKDOOR_PIDS[@]}"; do
    if ps -p "$pid" &>/dev/null; then
        echo "⚠️  ALERT: Backdoor process found (PID $pid)"
    fi
done

# Check for C2 connections
if netstat -an | grep "$C2_IP" &>/dev/null; then
    echo "🔴 CRITICAL: C2 connection active!"
fi

# Check for backdoor files
for path in "${BACKDOOR_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        echo "⚠️  ALERT: Backdoor file found: $path"
    fi
done
```

### Задание 3: Timeline Reconstruction

**Цель:** Понять последовательность событий

```bash
# Combine данные из:
# - lilith_alerts.txt (что было detected)
# - backdoor_analysis.txt (что реально происходило)

# Создай timeline:
# 08:47 UTC: DDoS starts (15 Gbps)
# 10:15 UTC: Zero-day detected
# 12:00 UTC: Backdoors activate
# ...
```

---

## 💡 Советы по работе с artifacts

### 1. Читай последовательно

```
Сначала: lilith_alerts.txt (общая картина)
Потом: backdoor_analysis.txt (детали)
```

### 2. Используй grep/awk для фильтрации

```bash
# Alerts в определённое время
grep "12:0" artifacts/monitoring/lilith_alerts.txt

# Только Critical
grep "P1" artifacts/monitoring/lilith_alerts.txt

# Backdoor упоминания
grep -i "backdoor" artifacts/forensics/backdoor_analysis.txt
```

### 3. Пиши notes во время чтения

```bash
# Создай свой analysis file
cat > my_analysis.txt <<EOF
Day 57 Timeline:
08:47 - DDoS starts
10:15 - Zero-day detected
12:00 - Backdoors activate

Key IOCs:
- C2 IP: 195.123.221.47
- PIDs: 8472, 3291, 9845, 2156, 7623

Questions:
- Why only 5/47 backdoors activated?
- How to prevent supply chain attacks?
EOF
```

### 4. Симулируй real-time response

```bash
# Представь: ты получаешь alerts в реальном времени
# Читай lilith_alerts.txt построчно
# На каждый CRITICAL alert — думай: что делать?

# Example:
# [08:47:42 UTC] P1 CRITICAL: DDoS confirmed - Stockholm 15 Gbps
# Твоё действие: iptables rate limiting? Kubernetes scaling?
```

---

## 🎓 Что ты должен вынести из этих artifacts

### Технические навыки

✅ **Alert analysis:** Умение читать и prioritize alerts
✅ **Forensics:** Понимание how backdoors work
✅ **Timeline reconstruction:** Умение собирать puzzle из logs
✅ **IOC extraction:** Находить indicators of compromise

### Концептуальное понимание

✅ **APT tactics:** Dormant backdoors, patience, timing
✅ **Supply chain risks:** Docker Hub compromise, image verification
✅ **Incident response:** Detection → Isolation → Forensics → Remediation
✅ **Team coordination:** Alerts → Analysis → Decision → Action

---

## 🚀 Следующие шаги

1. **Прочитай все artifacts** (30-60 минут)
2. **Выполни задания** из этого README
3. **Используй artifacts** в твоих scripts (starter/)
4. **Сравни** с solution/ когда закончишь

---

## 📚 Дополнительные ресурсы

**Если хочешь глубже:**

- **MITRE ATT&CK:** Backdoor techniques ([https://attack.mitre.org](https://attack.mitre.org))
- **Supply chain attacks:** Docker security best practices
- **Forensics tools:** AIDE, rkhunter, Volatility
- **APT case studies:** Real-world dormant malware incidents

---

**Artifacts = реалистичные данные из production incident.**

Используй их чтобы понять:
- Как выглядит real attack
- Как читать forensics reports
- Как принимать decisions under pressure

*"Artifacts — не просто файлы. Это evidence. Учись читать их как детектив."* — Anna Kovaleva

---

**Questions?** Check Episode 29 README.md или ask LILITH.

