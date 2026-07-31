# theory.md — s01e08 (углубление)

Один концепт и короткие фрагменты — в README. Здесь детали условий и циклов.

---

## Условия — развилка дороги

```bash
if [ УСЛОВИЕ ]; then
    # истина (условие вернуло 0)
elif [ ДРУГОЕ ]; then
    # вторая ветка
else
    # иначе
fi
```

`if` смотрит на **exit code**: `0` → then, не-`0` → else. Поэтому `if ping …; then`
работает напрямую — ветка выбирается по коду возврата команды.

**Операторы `[ … ]` (это команда `test`):**

Числа: `-eq -ne -gt -lt -ge -le` — `[ "$age" -ge 18 ]`.
Строки: `= != -z (пусто) -n (не пусто)` — `[ "$name" = "Max" ]`, `[ -z "$x" ]`.
Файлы: `-f (файл) -d (директория) -r -w -x -e (существует)` — `[ -f servers.txt ]`.

> Кавычки вокруг переменных внутри `[ … ]` обязательны: пустая переменная без
> кавычек ломает синтаксис теста.

## Циклы — конвейер

**for** — перебор списка:

```bash
for name in Max Viktor Dmitry; do echo "$name"; done
for i in 1 2 3; do echo "$i"; done
for ((i=1; i<=5; i++)); do echo "$i"; done   # C-style
```

**while** — пока условие истинно:

```bash
c=1
while [ "$c" -le 5 ]; do echo "$c"; c=$((c+1)); done
```

## Чтение файла построчно — золотой паттерн

```bash
while IFS= read -r line; do
    echo "$line"
done < servers.txt
```

- `IFS=` — не срезать ведущие/хвостовые пробелы.
- `read -r` — не трактовать `\` как escape.
- `< servers.txt` — перенаправить файл на вход цикла.

**Не делай так:** `for line in $(cat file)` — ломается на пробелах, грузит весь
файл в память, спотыкается на спецсимволах.

**Извлечь первое поле без `awk`** (его учим в s01e10+):

```bash
line="shadow-server-01 185.192.45.118"
host="${line%% *}"     # всё до первого пробела → shadow-server-01
```

`${var%% *}` — «отрезать самый длинный суффикс, начиная с пробела». Чистый bash.

## Ссылки

- `help test`, `help if`, `help while`, `help read`; `man bash` (Parameter Expansion)
- Shotts, «The Linux Command Line», гл. 27–29 (flow control, loops)
- Корневой [`RESOURCES.md`](../../RESOURCES.md)
