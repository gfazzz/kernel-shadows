# theory.md — s02e06 (углубление)

Один концепт и короткие фрагменты — в README. Здесь детали ufw / iptables.

---

## ufw — Uncomplicated Firewall

Дружелюбная обёртка над iptables (Type B: используем её, а не пишем свою).

```bash
sudo ufw default deny incoming     # по умолчанию — запрет входящих
sudo ufw default allow outgoing    # исходящие разрешены
sudo ufw allow 22/tcp              # разрешить SSH
sudo ufw allow 80,443/tcp          # web
sudo ufw deny from 185.220.101.47  # заблокировать IP
sudo ufw limit 22/tcp              # rate-limit (защита от brute-force)
sudo ufw enable                    # включить
sudo ufw status numbered           # правила с номерами
sudo ufw delete 3                  # удалить правило №3
```

> **Порядок спасения от самоблокировки:** сначала `ufw allow 22`, потом `ufw enable`.
> Иначе `enable` при default-deny оборвёт твою же SSH-сессию (recovery — только через консоль).

## iptables — под капотом

ufw управляет `iptables`. Пакеты проходят через **цепочки**:

```
INPUT    — входящие к этому хосту
OUTPUT   — исходящие от хоста
FORWARD  — транзитные (роутинг между интерфейсами)
```

Каждая цепочка имеет **политику по умолчанию** и список правил (сверху вниз, первое
совпадение выигрывает):

```bash
iptables -L -n -v                       # показать правила
iptables -P INPUT DROP                  # политика по умолчанию — запрет
iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # разрешить SSH
iptables -A INPUT -s 185.220.101.47 -j DROP     # заблокировать IP
```

**Принцип default-deny:** запретить всё, затем точечно разрешить нужное. Обратное
(«разрешить всё, запретить плохое») всегда дырявое — плохого бесконечно много.

`iptables-save > rules.v4` / `iptables-restore < rules.v4` — сохранить/восстановить
(правила иначе исчезают после ребута; персистентность — пакет `iptables-persistent`).
`nftables` — современная замена iptables (тот же смысл, новый синтаксис).

## Что аудит ищет в правилах

- Политика по умолчанию не `DROP`/`deny` — дыра.
- Чувствительные сервисы (`3306` MySQL, `6379` Redis, `5432` Postgres, `27017` Mongo,
  `9200` Elastic) открытые на `Anywhere`/`0.0.0.0` — их место за firewall или на `127.0.0.1`.
- Правила `ANY → ANY ACCEPT` — фактически выключенный firewall.

## Ссылки

- `man ufw`, `man iptables`; Nemeth — сетевая безопасность
- Корневой [`RESOURCES.md`](../../RESOURCES.md)
