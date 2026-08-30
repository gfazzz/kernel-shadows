# -*- coding: utf-8 -*-
"""Таблица серий сезона.

Собирается из шапок самих серий и лога последнего прогона `make test`,
а не пишется руками — поэтому не расходится с фактом.

    python3 tools/season_table.py season-01-shell-foundations

Вывод — markdown-таблица для раздела «Серии» в README сезона.
""" 
import glob, os, re, sys, subprocess

def field(t, k):
    m = re.search(rf'^{k}:\s*(.+?)\s*$', t, re.M)
    return m.group(1).strip() if m else ''

def head_tail(t, k):
    """Из строки «Тип: Type A — Automation           Время: ~45 мин   Сложность: ⭐»"""
    m = re.search(rf'{k}:\s*([^\s].*?)(?:\s{{2,}}|$)', t, re.M)
    return m.group(1).strip() if m else ''

def checks_map(season_dir):
    """Число проверок берётся из лога последнего прогона make test."""
    lg = os.path.join('tests', 'logs', os.path.basename(season_dir.rstrip('/')) + '.log')
    out, cur = {}, None
    if not os.path.exists(lg): return out
    for l in open(lg, encoding='utf-8', errors='replace'):
        m = re.search(r'=====\s+(s\d\de\d\d)', l)
        if m: cur = m.group(1); continue
        m2 = re.search(r'(\d+)\s+passed,\s*(\d+)\s+failed', l)
        if m2 and cur: out[cur] = m2.group(1)
    return out

def artifact(ep):
    """Имя артефакта — по файлу в starter/, а не по заголовку раздела."""
    files = [f for f in sorted(os.listdir(os.path.join(ep, 'starter')))
             if not f.startswith('.') and f != 'README.md'] if os.path.isdir(os.path.join(ep, 'starter')) else []
    if len(files) == 1: return f'`{files[0]}`'
    if files: return ', '.join(f'`{f}`' for f in files[:3])
    ms = os.path.join(ep, 'mission.md')
    if os.path.exists(ms):
        m = re.search(r'artifacts/([A-Za-z0-9_.-]+/?)', open(ms, encoding='utf-8').read())
        if m: return f'`{m.group(1)}`'
    return ''

def esc(s):
    return s.replace('|', '\\|')

CHK = checks_map(sys.argv[1])
rows = []
for ep in sorted(glob.glob(os.path.join(sys.argv[1], 's[0-9][0-9]e[0-9][0-9]*'))):
    r = open(os.path.join(ep, 'README.md'), encoding='utf-8').read()
    eid = os.path.basename(ep)[:6]
    title = r.split('\n')[0].lstrip('# ').strip()
    name = re.sub(r'^s\d\de\d\d\s*[—-]\s*', '', title)
    typ = head_tail(r, 'Тип').replace('Type ', '').split(' — ')[0]
    tm = head_tail(r, 'Время').replace('~', '')
    rows.append((eid, os.path.basename(ep), name, field(r, 'Концепт'), typ, tm, artifact(ep), CHK.get(eid, '')))

print('| Серия | Название | Концепт | Тип | Время | Артефакт | Проверок |')
print('|---|---|---|---|---|---|---|')
for eid, d, name, c, typ, tm, art, chk in rows:
    print(f'| [{eid}]({d}/) | {esc(name)} | {esc(c)} | {typ} | {tm} | {art} | {chk} |')
