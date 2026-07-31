# theory.md — s01e05 (углубление)

Один концепт и короткие фрагменты — в README. Здесь детали `find` и первого скрипта.

---

## `find` — рекурсивный радар

```bash
find [ГДЕ] [УСЛОВИЕ]
```

```bash
find . -name "briefing.txt"    # по точному имени, рекурсивно от "."
find . -name "*.txt"           # по маске
find . -name ".*"              # все скрытые
find . -type f                 # только файлы
find . -type d -name "docs"    # только директории с именем docs
find / -name "*.log" -size +100M   # большие логи по всей системе (медленно)
find . -perm -002              # world-writable — security-аудит
```

Где искать: `.` — здесь и во всех подпапках; `/` — вся система (медленно).

`-exec` выполняет команду над каждым найденным:

```bash
find . -type f -exec cat {} \;   # cat для каждого найденного; {} — путь, \; — конец
```

> `find .` — радар: сканирует всё дерево быстро и точно. Ядро — `-name`, `-type`,
> `-size`, `-perm`. Остальное по мере надобности.

---

## Первый bash-скрипт

```bash
#!/usr/bin/env bash   # shebang: чем запускать файл
set -euo pipefail     # строгий режим: падать на ошибке, ловить необъявленные переменные
echo "Hello"          # команды идут одна за другой
```

Запуск:

```bash
chmod +x script.sh    # сделать исполняемым
./script.sh           # запустить
```

Перенаправление вывода в файл:

```bash
echo "строка"  > report.txt    # перезаписать
echo "ещё"     >> report.txt   # дописать в конец
{ echo a; echo b; } | tee report.txt   # и на экран, и в файл
```

Подстановка команды — сохранить вывод в переменную:

```bash
briefing="$(find . -name 'briefing.txt' | head -1)"
```

`set -euo pipefail` — хорошая привычка с первого скрипта: `-e` падать на ошибке,
`-u` ошибка на необъявленной переменной, `pipefail` — ошибка в любом звене пайпа.
(Подробно про скрипты, переменные и условия — в следующем эпизоде, s01e06.)

## Ссылки

- `man find`, `man bash` (раздел про `set`), `help set`
- Shotts, «The Linux Command Line», гл. 17 «Searching for Files», гл. 24 «Writing Your First Script»
- Корневой [`RESOURCES.md`](../../RESOURCES.md)
