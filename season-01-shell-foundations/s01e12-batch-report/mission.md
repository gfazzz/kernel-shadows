# MISSION s01e12 — «Отчёт о готовности» (капстоун Season 1)

**Тип:** `Type B` — Linux Tools (dpkg/awk one-liners, минимум bash)
**Концепт:** batch-установка (`xargs`) + генерация отчёта
**Оценка времени:** ~55 минут

---

## Задача

Финал сезона. Виктору нужен **отчёт о готовности workstation**: что из списка стоит
(и каких версий), чего не хватает, и как доустановить недостающее одной командой.
Собери капстоун `install_report_generator.sh` (**Type B**).

**Артефакт:** `install_report_generator.sh` (в artifacts/).
Использование: `./install_report_generator.sh required_tools.txt install_report.txt`.

```bash
cp starter/install_report_generator.sh artifacts/install_report_generator.sh
# отредактируй TODO, затем:
bash tests/test.sh
```

> Это НЕ обёртка для apt. Установка — `sudo apt install` напрямую; batch — one-liner
> `grep -v '^#' tools.txt | awk '{print $1}' | xargs sudo apt install -y`. Скрипт лишь
> генерирует отчёт о статусе.

---

## Критерии приёмки

`bash tests/test.sh` зелёный (10 проверок). Отчёт содержит:

1. По каждому пакету: `✓ pkg (версия)` или `✗ pkg — НЕ установлен` (статус через `dpkg`).
2. Версию установленного (`dpkg -l pkg | awk '/^ii/{print $3}'`).
3. Статистику `Установлено из списка: N / M`.
4. Batch one-liner для недостающего (`xargs … apt install`).
5. Пропуск комментариев/пустых; сохранение отчёта в файл; отсутствующий файл → ненулевой exit.

> Тест **мокает `dpkg`** (включая `--print-architecture`) — без root/apt/Ubuntu.

---

## Требования среды

| Требование | Значение |
|------------|----------|
| root / sudo | не нужен (для теста; batch-install — с `sudo`) |
| ОС | любая с bash + awk (тест мокает `dpkg`) |
| Сеть | не нужна |
| systemd / Docker | не нужны |
| Внешние пакеты | в реальном запуске — `dpkg`; в тесте подменяется |
| Изоляция теста | мок-`dpkg` + фикстура-манифест во временном `TEST_ROOT` |

---

## Definition of Done

- [ ] `install_report_generator.sh` проходит `tests/test.sh` (10/10).
- [ ] Это **Type B**: работу делают `dpkg`/`awk`, bash — клей и цикл по списку.
- [ ] Знаешь batch-идиому `xargs` и понимаешь, когда она уместна.
- [ ] (Капстоун Season 1) Соединил навыки сезона: чтение файла, цикл, условия, инструменты, отчёт.
- [ ] (Кумулятивность) Отчёт закрывает setup-фазу `shadow_toolkit` — workstation готова к S2.
