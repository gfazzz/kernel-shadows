# Dockerfile для ops/collector (СТАРТЕР)
#
# Тот самый файл на двенадцать строк, из которого собрался образ,
# разобранный в s04e04. Он работает. Из него получается ключ в слое,
# пароль в переменных, контейнер от root и база на гигабайт.
#
# Правь этот файл в artifacts/, потом проверяй:  bash tests/test.sh
#
# Что должно получиться (подробности — в mission.md):
#   точная и облегчённая база; порядок инструкций, при котором кеш
#   не сбрасывается на каждой правке кода; ни одного секрета внутри;
#   работа не от root; запуск в exec-форме.

FROM python:3.11

WORKDIR /app

ENV DB_PASSWORD=Sh4dow-Pr0d-2025!

RUN apt-get update && apt-get install -y curl git build-essential

COPY deploy_key /tmp/deploy_key

RUN pip install -r /app/requirements.txt

RUN rm -rf /tmp/deploy_key

COPY . /app

USER root

CMD python /app/collector.py
