# MISSION s02e09 — «Закалённый вход» (капстоун Season 2)

**Тип:** `Type B` — Linux Configuration (аудит `sshd_config`)
**Концепт:** hardening SSH-сервера + SSH-туннели
**Оценка времени:** ~55 минут

---

## Задача

Ключи у команды есть, но сервер всё ещё пускает по паролю и разрешает root-логин — дыры,
которыми воспользуется Крылов. Собери капстоун `sshd_harden_check.sh`: аудит `sshd_config`
по ключевым директивам закалки.

**Артефакт:** `sshd_harden_check.sh` (в artifacts/).
Использование: `./sshd_harden_check.sh /etc/ssh/sshd_config`.

```bash
cp starter/sshd_harden_check.sh artifacts/sshd_harden_check.sh
# отредактируй TODO, затем:
bash tests/test.sh
```

> Реальный `sshd` и рестарт службы не нужны — **читаем** конфиг из файла (безопасно, воспроизводимо).

---

## Критерии приёмки

`bash tests/test.sh` зелёный (9 проверок). Ключевое:

1. Корректный bash-скрипт с shebang.
2. Проверяет `PermitRootLogin no`, `PasswordAuthentication no`, `PermitEmptyPasswords no`, `X11Forwarding no`.
3. Берёт **активное** значение (закомментированные строки игнорируются).
4. Не заданная директива с небезопасным дефолтом — тоже флаг.
5. Слабый конфиг → ≥3 проблемы; закалённый → 0.

---

## Требования среды

| Требование | Значение |
|------------|----------|
| root / sudo | не нужен (аудит читает файл; применение — с root) |
| ОС | любая с bash |
| Сеть | не нужна |
| systemd / Docker | не нужны |
| Внешние пакеты | нет |
| Изоляция теста | фикстуры-`sshd_config` во временном `TEST_ROOT` |

---

## Definition of Done

- [ ] `sshd_harden_check.sh` проходит `tests/test.sh` (9/9).
- [ ] Знаешь ключевые директивы закалки sshd и почему каждая важна.
- [ ] Понимаешь SSH-туннели: `-L` (local), `-R` (remote), `-D` (dynamic/SOCKS) — см. `theory.md`.
- [ ] Знаешь идею VPN (WireGuard/ChaCha20) — шифрование всего трафика против DPI.
- [ ] (Капстоун Season 2) Соединил ключи → hardening → шифрование в защищённый доступ.
- [ ] (Кумулятивность) `netshield` завершён: адресация, DNS-защита, firewall, шифрованный доступ.
