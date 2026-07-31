# theory.md — s01e12 (углубление)

Один концепт и короткие фрагменты — в README. Здесь детали `apt`, `dpkg`, репозиториев.

---

## apt — основной инструмент

```bash
sudo apt update              # обновить индекс пакетов (регулярно!)
apt search nmap              # найти пакет
apt show nmap                # информация о пакете
sudo apt install nmap        # установить
sudo apt remove nmap         # удалить (конфиги оставить)
sudo apt purge nmap          # удалить полностью
sudo apt autoremove          # убрать осиротевшие зависимости
sudo apt upgrade             # обновить установленные
apt list --installed         # что стоит
apt list --upgradable        # что можно обновить
```

| Команда | sudo | частота |
|---------|------|---------|
| `update` | да | ежедневно |
| `upgrade` | да | еженедельно |
| `search`/`show` | нет | часто |
| `install` | да | часто |
| `remove`/`purge` | да | редко |
| `autoremove` | да | после remove |

**apt vs apt-get:** `apt` — для людей (прогресс-бар, цвет); `apt-get`/`apt-cache` —
стабильный вывод для скриптов. Но здесь Type B: используем `apt` напрямую, а не пишем обёртки.

## dpkg — низкий уровень

`apt` работает поверх `dpkg` (Debian package manager). Прямые проверки:

```bash
dpkg -l                 # все установленные пакеты
dpkg -l nmap            # статус пакета: строка "ii" = installed ok
dpkg -s nmap            # подробный статус
dpkg -L nmap            # какие файлы принёс пакет
dpkg -S /usr/bin/nmap   # какому пакету принадлежит файл
dpkg --print-architecture   # amd64 / arm64 ...
```

Первые два символа в `dpkg -l`: `ii` = установлен корректно; `rc` = удалён, остались конфиги.

## Репозитории — откуда берутся пакеты

- Списки источников: `/etc/apt/sources.list` и `/etc/apt/sources.list.d/*.list`.
- Строка репозитория: `deb <url> <дистрибутив> <компоненты>`
  (например `deb http://archive.ubuntu.com/ubuntu jammy main universe`).
- PPA: `sudo add-apt-repository ppa:...` (сторонние сборки).
- GPG-ключи подтверждают подлинность пакетов; без доверенного ключа apt откажется ставить.

> **Про Docker (T3).** Раньше этот эпизод заставлял ставить `docker-ce` из кастомного
> репозитория ещё до того, как Docker вообще объясняется (это forward-dep). В v2.0
> Docker ставится там, где преподаётся, — в Season 4. Здесь учимся `apt`/`dpkg` на
> безопасных, сразу нужных пакетах (git, curl, jq, htop…).

## Ссылки

- `man apt`, `man dpkg`, `man sources.list`
- Shotts, «The Linux Command Line», гл. 15 «Packaging»
- Nemeth, «UNIX and Linux System Administration Handbook» — гл. про управление ПО
- Корневой [`RESOURCES.md`](../../RESOURCES.md), метки Type — [`PROJECTS.md`](../../PROJECTS.md)
