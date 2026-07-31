# theory.md — s01e12 (углубление)

Один концепт и короткие фрагменты — в README. Здесь детали batch-операций и отчёта.

---

## Batch-установка через xargs

`xargs` берёт строки со stdin и подставляет их как аргументы команде — так список
пакетов превращается в один вызов `apt install`:

```bash
# tools.txt: по пакету на строку (# — комментарии)
grep -v '^#' tools.txt | awk '{print $1}' | xargs sudo apt install -y
#     убрать комментарии    взять имя         передать все имена одной командой
```

Полезные флаги:

| Флаг | Действие |
|------|----------|
| `-n N` | по N аргументов за вызов |
| `-P N` | N параллельных процессов |
| `-I {}` | подставлять `{}` в шаблон команды |
| `-r` | не запускать команду, если вход пуст (GNU) |
| `-0` | разделитель — NUL (в паре с `find -print0`) |

> Один `apt install pkg1 pkg2 pkg3` лучше трёх отдельных: apt один раз посчитает
> зависимости и один раз обновит систему.

## Verification & cleanup

```bash
dpkg -l pkg | grep '^ii'     # реально ли установлен
apt list --installed          # всё установленное
sudo apt autoremove           # убрать осиротевшие зависимости
sudo apt clean                # очистить кэш скачанных .deb (/var/cache/apt/archives)
du -sh /var/cache/apt/archives/   # сколько занимает кэш
```

## Отчёт (Type B one-liners)

Тело отчёта — из уже знакомых инструментов:

```bash
{
  echo "Всего в системе: $(dpkg -l | grep -c '^ii')"
  while IFS= read -r p; do
      case "$p" in \#*|'') continue ;; esac
      pkg="${p%% *}"
      dpkg -l "$pkg" 2>/dev/null | grep -q '^ii' \
          && echo "✓ $pkg" || echo "✗ $pkg"
  done < tools.txt
} > report.txt
```

bash здесь — только цикл и клей; проверку и данные дают `dpkg`/`grep`/`awk`. Это и есть Type B.

## Ссылки

- `man xargs`, `man apt`, `man dpkg`
- Shotts, «The Linux Command Line», гл. 15 «Packaging», гл. 20 (xargs в конвейерах)
- Корневой [`RESOURCES.md`](../../RESOURCES.md)
