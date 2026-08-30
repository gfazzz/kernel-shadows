#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Вставляет свежий указатель серий в docs/CURRICULUM.md.

Указатель собирается tools/gen_index.sh из шапок серий. Здесь он только
подставляется между «## Указатель серий» и итоговой строкой, чтобы
CURRICULUM не поддерживался руками и не расходился с курсом.

    python3 tools/update_index.py
"""
import subprocess, sys

DOC = 'docs/CURRICULUM.md'
HEAD = '## Указатель серий'
TAIL = '**Всего: 101 серия'

gen = subprocess.run(['bash', 'tools/gen_index.sh'],
                     capture_output=True, text=True, check=True).stdout.strip()
t = open(DOC, encoding='utf-8').read()
a = t.find(HEAD)
b = t.find(TAIL, a)
if a < 0 or b < 0:
    sys.exit(f'{DOC}: не найдены границы указателя ({HEAD!r} / {TAIL!r})')
# генератор печатает и таблицы, и итоговую строку — вторую отбрасываем
gen = gen.split('**Всего:')[0].rstrip().rstrip('-').rstrip()
open(DOC, 'w', encoding='utf-8').write(t[:a] + HEAD + '\n\n' + gen + '\n\n---\n\n' + t[b:])
print(f'{DOC}: указатель обновлён')
