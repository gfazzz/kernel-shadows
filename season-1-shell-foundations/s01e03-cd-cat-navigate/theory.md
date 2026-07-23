# theory.md — s01e03 (углубление)

Один концепт и короткие фрагменты — в README. Здесь детали навигации и чтения.

---

## `cd` — телепортация по дереву

`cd` = **C**hange **D**irectory. В отличие от реального мира, перемещение мгновенно.

```bash
cd documents        # относительный путь — отсюда внутрь documents/
cd /etc             # абсолютный путь — от корня
cd ..               # на уровень вверх (родитель)
cd ../..            # на два уровня вверх
cd ~                # домой ($HOME)
cd /                # в корень
cd -                # назад, в предыдущую директорию
cd                  # без аргумента — тоже домой
```

Путешествие:

```console
$ pwd
/home/max
$ cd documents;  pwd
/home/max/documents
$ cd ../downloads;  pwd
/home/max/downloads
$ cd ~;  pwd
/home/max
$ cd /etc;  pwd
/etc
$ cd -;  pwd
/home/max
```

**Пробелы в именах** ломают навигацию: `cd My Documents` → bash видит два
аргумента. Решения: `cd "My Documents"` или `cd My\ Documents`. Лучше — не
использовать пробелы: `my_documents`, `my-documents`, `MyDocuments`.

**Абсолютный vs относительный при навигации.** Из
`/home/max/projects/web/frontend/src` быстрее всего в `/etc/nginx` — командой
`cd /etc/nginx` (абсолютный), а не считать `../../../../..`.

---

## `cat` / `less` / `head` / `tail` — прочитать файл

```bash
cat file.txt         # вывести весь файл сразу (для маленьких)
less file.txt        # постраничная "читалка" (для больших); q — выход
head -n 20 file.txt  # первые 20 строк
tail -n 50 file.txt  # последние 50 строк
tail -f app.log      # следить за логом в реальном времени
```

| Задача | Команда |
|--------|---------|
| маленький файл | `cat file` |
| большой файл | `less file` |
| первые строки | `head -n N file` |
| последние строки | `tail -n N file` |
| следить за логом | `tail -f /var/log/app.log` |
| поиск в файле | `less file`, затем `/шаблон` |

Управление в `less`: `Space`/`PgDown` — вперёд, `b`/`PgUp` — назад,
`/текст` — поиск вперёд, `?текст` — назад, `q` — выход.

> `cat` большого лога зальёт весь экран. `less` — листаешь и ищешь.
> `tail -f` — маст-хэв для наблюдения за логами (Season 3 и дальше).

## Ссылки

- `man cd` (встроенная в bash — `help cd`), `man cat`, `man less`, `man tail`
- Shotts, «The Linux Command Line», гл. 3 «Exploring the System»
- Корневой [`RESOURCES.md`](../../RESOURCES.md)
