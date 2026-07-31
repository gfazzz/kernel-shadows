# KERNEL SHADOWS: Episode 14 — Docker Basics
# Production-ready Dockerfile for Nginx web server
# Amsterdam, Netherlands (Day 27-28)
# Sophie van Dijk, Docker Architect

# TODO 1: Выбери базовый образ
# Подсказка: FROM nginx:alpine
# alpine — минимальный Linux дистрибутив (~5MB vs ~100MB Ubuntu)
# Используй alpine для production: меньше размер, меньше уязвимостей
FROM ???

# TODO 2: Добавь метаданные (LABEL)
# Подсказка: 
# LABEL maintainer="твой-email" \
#       version="1.0" \
#       description="Nginx web server for Operation Shadow"
#
# LABEL — метаданные для образа (кто создал, версия, описание)
# Помогают в production: docker inspect покажет эту информацию
LABEL maintainer="???" \
      version="???" \
      description="???" \
      episode="14" \
      location="Amsterdam, Netherlands"

# TODO 3: Установи curl для healthcheck
# Подсказка: RUN apk add --no-cache curl
# apk — пакетный менеджер Alpine Linux (apt для Ubuntu, yum для CentOS)
# --no-cache — не сохранять кеш (экономит место)
RUN ???

# TODO 4: Скопируй конфигурационные файлы
# Подсказка:
# COPY configs/nginx.conf /etc/nginx/nginx.conf
# COPY html/ /usr/share/nginx/html/
#
# COPY — копирует файлы из host в container
# Порядок важен: часто меняющиеся файлы копируй в конце (Docker layer caching)
COPY ??? ???
COPY ??? ???

# TODO 5: Создай непривилегированного пользователя nginx
# Подсказка: RUN addgroup -S nginx && adduser -S nginx -G nginx
# SECURITY: НЕ запускай приложения от root в контейнере!
# -S — system user (без пароля, нет домашней директории)
RUN ???

# TODO 6: Установи правильные permissions
# Подсказка:
# RUN chown -R nginx:nginx /usr/share/nginx/html && \
#     chown -R nginx:nginx /var/cache/nginx && \
#     chown -R nginx:nginx /var/log/nginx && \
#     touch /var/run/nginx.pid && \
#     chown -R nginx:nginx /var/run/nginx.pid
#
# Nginx должен иметь доступ к:
# - /usr/share/nginx/html (веб-файлы)
# - /var/cache/nginx (кеш)
# - /var/log/nginx (логи)
# - /var/run/nginx.pid (PID файл)
RUN chown -R nginx:nginx ??? && \
    chown -R nginx:nginx ??? && \
    chown -R nginx:nginx ??? && \
    touch ??? && \
    chown -R nginx:nginx ???

# TODO 7: Переключись на непривилегированного пользователя
# Подсказка: USER nginx
# SECURITY: После этой строки все команды выполняются от nginx (не root)
USER ???

# TODO 8: Открой порт 80
# Подсказка: EXPOSE 80
# EXPOSE — документирует какие порты использует контейнер
# НЕ публикует порт наружу (это делает docker run -p)
EXPOSE ???

# TODO 9: Добавь healthcheck
# Подсказка:
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#   CMD curl -f http://localhost/health || exit 1
#
# HEALTHCHECK — Docker будет периодически проверять здоровье контейнера
# --interval=30s — проверять каждые 30 секунд
# --timeout=3s — ждать ответа максимум 3 секунды
# --start-period=5s — не проверять первые 5 секунд (даём время запуститься)
# --retries=3 — пометить unhealthy после 3 неудачных попыток
HEALTHCHECK --interval=??? --timeout=??? --start-period=??? --retries=??? \
  CMD ???

# TODO 10: Укажи команду запуска
# Подсказка: CMD ["nginx", "-g", "daemon off;"]
# CMD — команда по умолчанию при запуске контейнера
# "daemon off;" — запускать nginx в foreground (не в фоне)
# Docker требует foreground процесс (иначе контейнер сразу завершится)
CMD ???

# ============================================================================
# СПРАВКА: Как использовать после заполнения TODO
#
# 1. Build образ:
#    docker build -t operation-shadow/web:latest .
#
# 2. Запустить контейнер:
#    docker run -d -p 8080:80 --name shadow-web operation-shadow/web:latest
#
# 3. Проверить статус:
#    docker ps
#    docker logs shadow-web
#
# 4. Проверить healthcheck:
#    docker inspect shadow-web | grep -A 10 Health
#
# 5. Тестировать веб-сервер:
#    curl http://localhost:8080
#    curl http://localhost:8080/health
#
# 6. Остановить и удалить:
#    docker stop shadow-web
#    docker rm shadow-web
#
# ============================================================================
# ВОПРОСЫ ДЛЯ ПОНИМАНИЯ:
#
# 1. Зачем использовать alpine вместо ubuntu?
#    → alpine ~5MB, ubuntu ~100MB
#    → Меньше размер = быстрее скачивание, меньше уязвимостей
#    → Для production всегда используй минимальные образы
#
# 2. В чём разница между COPY и ADD?
#    → COPY — просто копирует файлы
#    → ADD — копирует + распаковывает tar архивы + скачивает URL
#    → Best practice: используй COPY (более предсказуемо)
#
# 3. Почему USER nginx, а не USER root?
#    → SECURITY! Если контейнер скомпрометирован, атакующий получит
#      только права nginx (не root)
#    → Принцип наименьших привилегий
#
# 4. Зачем HEALTHCHECK?
#    → Docker/Kubernetes будут автоматически перезапускать unhealthy контейнеры
#    → Предотвращает ситуацию когда контейнер работает, но приложение зависло
#
# 5. Почему "daemon off;" в CMD?
#    → Docker требует foreground процесс
#    → Если nginx уйдёт в background, Docker подумает что процесс завершился
#      и остановит контейнер
#
# 6. В чём разница между CMD и ENTRYPOINT?
#    → CMD — команда по умолчанию (можно переопределить при docker run)
#    → ENTRYPOINT — команда которая ВСЕГДА выполняется
#    → Пример: ENTRYPOINT ["nginx"] + CMD ["-g", "daemon off;"]
#
# 7. Что такое Docker layers?
#    → Каждая инструкция (FROM, RUN, COPY) создаёт новый layer
#    → Layers кешируются — если файл не изменился, layer переиспользуется
#    → Best practice: часто меняющиеся файлы копируй в конце
#
# 8. Зачем --no-cache в apk add?
#    → apk сохраняет кеш пакетов в /var/cache/apk/
#    → В контейнере кеш не нужен (не будем устанавливать пакеты после build)
#    → Экономит ~10-50MB в финальном образе
#
# ============================================================================
# Docker Best Practices (из Sophie's notes):
#
# ✅ DO:
# - Используй alpine/slim образы для production
# - Запускай от непривилегированного пользователя (USER)
# - Добавляй HEALTHCHECK
# - Минимизируй количество layers (объединяй RUN команды)
# - Используй .dockerignore (как .gitignore)
# - Добавляй LABEL с метаданными
# - Используй multi-stage builds для языков компиляции (Go, Java, etc.)
#
# ❌ DON'T:
# - НЕ запускай от root (USER root)
# - НЕ устанавливай ненужные пакеты
# - НЕ копируй secrets в образ (используй Docker secrets)
# - НЕ используй latest tag в production (используй версии)
# - НЕ запускай apt-get upgrade в Dockerfile (используй новый базовый образ)
# - НЕ храни данные в контейнере (используй volumes)
#
# ============================================================================
# Метафора от Sophie:
#
# "Dockerfile — это рецепт. Image — это готовое блюдо. Container — это
#  тарелка с блюдом на столе. Ты можешь создать много контейнеров
#  (тарелок) из одного образа (блюда)."
#
# ============================================================================
# Sophie van Dijk: "Containers zijn als LEGO. Simple blocks, complex systems.
#                   Build once, run anywhere."
# ============================================================================

