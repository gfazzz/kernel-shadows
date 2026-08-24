# Четыре снимка одного выката

Каждый каталог — состояние `Deployment aurora-api`, снятое через минуту
после `kubectl apply`. Внутри всегда одни и те же четыре файла:

| Файл | Команда |
|---|---|
| `deploy.txt` | `kubectl get deploy aurora-api -o yaml` (spec, status, conditions) |
| `rs.txt` | `kubectl get rs -l app=aurora-api` |
| `pods.txt` | `kubectl get pods -l app=aurora-api` |
| `events.txt` | `kubectl get events --sort-by=.lastTimestamp` |

Плюс пятый файл — `truth.txt`. В нём записано, чем закончился настоящий
`kubectl rollout status --timeout=120s`: его вывод и код возврата.

**`rollout_check.sh` не должен открывать `truth.txt`.** Он обязан прийти к
тому же выводу по первым четырём файлам — тест это проверяет отдельно,
поиском имени файла в тексте скрипта. Смысл упражнения в том, чтобы
отличать «выкат идёт» от «выкат встал» по состоянию, а не ждать таймаута.
