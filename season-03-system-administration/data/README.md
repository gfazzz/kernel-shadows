# data/ — учебные данные Season 3

Снимки со скомпрометированного `shadow-server-01`, снятые Анной Ковалёвой
17 октября до того, как на машине что-либо меняли. Разбираются копии, поэтому
ни root, ни живая система для прохождения не нужны.

## Что где

| Файл | Для серий | Что это |
|------|-----------|---------|
| `passwd_shadow-01.txt` | s03e01 | снимок `/etc/passwd` — учётные записи, UID, оболочки |
| `group_shadow-01.txt` | s03e01 | снимок `/etc/group` — группы и их состав |
| `shadow_shadow-01.txt` | s03e01 | снимок `/etc/shadow`, хеши обрезаны при выемке |
| `perm_audit_shadow-01.txt` | s03e02 | вывод `ls -l` по ключевым путям |
| `suid_scan_shadow-01.txt` | s03e02 | результат `find / -perm -4000 -o -perm -2000` |
| `ps_shadow-01.txt` | s03e04 | таблица процессов, снята 17.10 в 07:42 |
| `proc_shadow-01.txt` | s03e04 | `exe`, `cwd`, `cmdline`, `status`, `fd` по четырём PID |

## Как пользоваться

```bash
cd season-03-system-administration
D=data
noc() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

noc $D/passwd_shadow-01.txt | awk -F: '$3 == 0 {print $1}'      # все UID 0
grep -E '^[-dl]' $D/suid_scan_shadow-01.txt | awk '$1 ~ /^-..s/'  # SUID-файлы
grep -vE '^#|^USER' $D/ps_shadow-01.txt | awk '$6 ~ /^Z/'         # зомби
awk '/^=== /{p=$0; gsub(/[^0-9]/,"",p)} /^exe -> /{print p, $0}' $D/proc_shadow-01.txt
```

> В снимках намеренно оставлены следы вторжения и обычная небрежность
> администраторов — различать одно и другое и есть задача серий.
> Проверить себя на своей машине: `getent passwd`, `id`,
> `find / -xdev -perm -4000 -type f -ls 2>/dev/null`.
