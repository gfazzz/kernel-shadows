# theory.md — s02e03 (углубление)

Один концепт и короткие фрагменты — в README. Здесь детали `ping`, `traceroute`, `tcpdump`.

---

## ping / ICMP — «эхо в пещере»

`ping` шлёт ICMP Echo Request и ждёт Echo Reply — как крик в пещере и эхо в ответ.

```bash
ping -c 4 8.8.8.8        # 4 пакета
ping -c 1 -W 2 host      # 1 пакет, таймаут 2с (для скриптов)
```

Вывод несёт диагностику:

```
64 bytes from 8.8.8.8: icmp_seq=0 ttl=57 time=12.3 ms
--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
```

- `time=` — RTT (round-trip time), задержка туда-обратно.
- `packet loss` — потери; рост RTT и потери = перегрузка или атака (DDoS).
- `ttl` — сколько «прыжков» осталось у пакета (уменьшается на каждом роутере).

Ненулевой exit `ping` ≠ всегда «мёртв»: хост может блокировать ICMP. Для скриптов
берут exit code + парсят `time=`.

## traceroute — «почтовые станции»

Показывает путь пакета через маршрутизаторы (каждый хоп — «почтовая станция»):

```bash
traceroute 8.8.8.8       # список хопов с задержками
tracepath 8.8.8.8        # без root
mtr 8.8.8.8              # traceroute + ping в реальном времени
```

Работает через TTL: пакеты с TTL=1,2,3… «умирают» на 1-м, 2-м, 3-м роутере, и каждый
присылает ICMP «Time Exceeded» — так мы видим цепочку. Где путь обрывается —
там и проблема (обрыв, firewall, «чёрная дыра»).

## ip route — куда пойдёт пакет

```bash
ip route                 # таблица маршрутизации
ip route get 8.8.8.8     # каким маршрутом пойдёт пакет к 8.8.8.8
```

`default via <gateway>` — шлюз по умолчанию (куда уходит всё, что не в локальной сети).

## tcpdump — «прослушка сети» (превью)

```bash
sudo tcpdump -i any icmp        # видеть ICMP-пакеты вживую
sudo tcpdump -i any port 53     # DNS-трафик
```

Показывает реальные пакеты на интерфейсе. Требует root. Мощный инструмент форензики —
им ловят и атаку, и собственную ошибку. Подробно — в Season 5.

## Ссылки

- `man ping`, `man traceroute`, `man ip`, `man tcpdump`
- Nemeth, «UNIX and Linux System Administration Handbook» — диагностика сети
- Корневой [`RESOURCES.md`](../../RESOURCES.md)
