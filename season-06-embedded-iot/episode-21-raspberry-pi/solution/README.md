# Solution — Episode 21: Raspberry Pi & GPIO

## ⚠️ Для инструктора / После завершения

Production-ready Raspberry Pi surveillance system.

## 📁 Содержимое

### 1. c-code/
Complete GPIO control program:
- `gpio_control.c` — Working GPIO LED control
- `Makefile` — Production compilation

### 2. configs/
Production configurations:
- `config.txt` — Optimized boot config
- `systemd/` — Автозапуск сервисов

### 3. camera_stream.sh
Working camera streaming script

---

## 📊 Solution Highlights

**GPIO Control:**
- ✅ Proper libgpiod usage
- ✅ Error handling
- ✅ Resource cleanup
- ✅ Safety checks

**Camera Streaming:**
- ✅ H.264 encoding
- ✅ Network streaming via ffmpeg
- ✅ Auto-restart on failure

**Production Ready:**
- ✅ systemd service для автостарта
- ✅ Logging
- ✅ Security hardening

---

## ✅ Критерии оценки

Студент должен достичь:
- ✅ GPIO control program компилируется
- ✅ LED успешно blinks
- ✅ Camera stream работает
- ✅ SSH access настроен
- ✅ Systemd service создан (bonus)

Бонус:
- Encryption streaming
- Multiple sensors
- Web dashboard

---

> **Эти конфиги — production-ready для surveillance system!**
