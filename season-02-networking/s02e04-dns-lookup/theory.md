# theory.md — s02e04 (углубление)

Один концепт и короткие фрагменты — в README. Здесь детали DNS, `dig`, конфигов.

---

## DNS — телефонная книга интернета

Люди помнят имена, компьютеры — IP. DNS переводит `google.com` → `142.250.185.46`.
Простая идея — критичная уязвимость: кто контролирует DNS, тот решает, куда пойдёт трафик.

## Инструменты запроса

```bash
dig google.com A +short      # короткий ответ (только значения)
dig google.com MX +short     # почтовые серверы
dig +trace google.com        # полный путь резолва (root → TLD → authoritative)
host google.com              # проще dig
nslookup google.com          # классика (интерактивный)
resolvectl query google.com  # через systemd-resolved (Ubuntu), read-only
```

> **systemd-resolved (T2-примечание).** На Ubuntu резолвер по умолчанию —
> `systemd-resolved`; запрос к нему — `resolvectl query`. Управление самим сервисом
> (`systemctl restart systemd-resolved`) — это **systemd**, его разбираем в **Season 3**.
> Здесь читаем DNS, а не рестартуем службы.

## Типы записей

| Тип | Что | Пример |
|-----|-----|--------|
| A | IPv4 | `142.250.185.46` |
| AAAA | IPv6 | `2a00:1450:4001:830::200e` |
| MX | почта (приоритет!) | `5 gmail-smtp-in.l.google.com.` |
| NS | name server домена | `ns1.google.com.` |
| CNAME | алиас | `www → github.com` |
| TXT | текст (SPF/DKIM/verify) | `"v=spf1 ..."` |
| PTR | reverse (IP → имя) | `dig -x 8.8.8.8` |
| SOA | authority зоны | — |

**MX-приоритет контринтуитивен:** меньше число = важнее. `5` — основной, `10` — backup.

## Локальная конфигурация

- `/etc/hosts` — локальная «телефонная книга», **приоритет над DNS**:
  `10.50.1.2  shadow-server-02` → имя резолвится локально, DNS не спрашивается.
  (Атакующий, дописавший строку в `/etc/hosts`, перенаправит твой трафик — проверяй этот файл.)
- `/etc/resolv.conf` — какие DNS-серверы использовать (`nameserver 8.8.8.8`).
  На Ubuntu им управляет `systemd-resolved` (не редактируй напрямую — символическая ссылка).

Порядок резолва задаёт `/etc/nsswitch.conf` (`hosts: files dns` — сначала `/etc/hosts`, потом DNS).

## Ссылки

- `man dig`, `man host`, `man resolvectl`, `man hosts`, `man resolv.conf`
- Nemeth, «UNIX and Linux System Administration Handbook» — DNS
- Корневой [`RESOURCES.md`](../../RESOURCES.md)
