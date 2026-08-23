#!/usr/bin/env bash
#
# rollout_check.sh — «выкат идёт или встал» (СТАРТЕР)
#
# С Season 7 каркас содержит только договор: как вызывают, что печатать,
# что возвращать. Как именно — решаешь сам.
#
# ВЫЗОВ
#   rollout_check.sh <каталог-снимка>
#
# ВХОД (в каталоге, описание — в data/README.md)
#   deploy.txt   spec, status и conditions Deployment
#   rs.txt       kubectl get rs: NAME DESIRED CURRENT READY AGE
#   pods.txt     kubectl get pods: NAME READY STATUS RESTARTS AGE
#   events.txt   kubectl get events
#
#   truth.txt в каталоге тоже есть — в нём записано, чем кончился настоящий
#   `kubectl rollout status`. Открывать его нельзя: смысл упражнения в том,
#   чтобы прийти к тому же выводу по состоянию. Тест это проверяет.
#
# ВЫВОД — ровно восемь строк, в этом порядке:
#   VERDICT     complete | progressing | stuck
#   CAUSE       none | scheduling | image | readiness | deadline
#   DESIRED     сколько реплик заказано
#   UPDATED     сколько уже новой версии
#   AVAILABLE   сколько доступно
#   NEW-RS      имя нового ReplicaSet
#   OLD-RS      имя прежнего и сколько реплик за ним осталось
#   PROGRESSING статус и причина условия Progressing
#
# КОД ВОЗВРАТА
#   0 — идёт или доехал     1 — встал     2 — снимок не разобрать
#
# ПОДСКАЗКИ К РЕШЕНИЮ (не к коду)
#   - «Доехал» — это три равенства сразу, а не одно.
#   - Кластер признаёт неудачу условием Progressing=False, но только через
#     progressDeadlineSeconds. До этого о безнадёжности говорят события.
#   - Отличить новый ReplicaSet от старого можно лишь по возрасту: имя —
#     это хеш шаблона, порядка в нём нет. AGE бывает «50s», «14m», «6h».
#   - Поды нового ReplicaSet узнаются по хешу в имени.

set -uo pipefail

DIR="${1:-}"
if [ -z "${DIR}" ] || [ ! -d "${DIR}" ]; then
    echo "usage: $(basename "$0") <каталог-снимка>" >&2
    exit 2
fi

# TODO: разобрать deploy.txt — desired, updated, available, replicas,
#       статус и причина условия Progressing.

# TODO: найти новый и старый ReplicaSet в rs.txt.

# TODO: отобрать поды нового ReplicaSet и посмотреть, что с ними.

# TODO: собрать предупреждения о них из events.txt.

# TODO: вывести восемь строк и вернуть нужный код.

echo "VERDICT unknown"
exit 2
