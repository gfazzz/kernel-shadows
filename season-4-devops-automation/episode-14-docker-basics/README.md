# EPISODE 14: DOCKER BASICS 🐳🇳🇱

> **"Containers zijn als LEGO. Simple blocks, complex systems. Build once, run anywhere."**
> — Sophie van Dijk, Docker Architect

---

## 📍 Контекст операции

**День:** 27-28 из 60
**Локация:** 🇳🇱 Amsterdam, Netherlands (Science Park datacenter)
**Время:** 5-6 часов
**Сложность:** ⭐⭐⭐☆☆

**Предыдущий эпизод:** [Episode 13: Git & Version Control](../episode-13-git-version-control/README.md) (Berlin, Germany)
**Следующий эпизод:** Episode 15: CI/CD Pipelines (Berlin, Germany)

---
## 🎬 Сюжет

### Переход Episode 13 → Episode 14

**Hans Müller (прощание в Берлине, день 26):**
> *"Макс, Дмитрий — git foundation готов. Теперь контейнеры. Sophie van Dijk в Амстердаме — бывший Docker Inc. architect. Если кто знает Docker, то это она. Летите завтра. И помните что сказал Алекс: supply chain attacks на Docker images. Проверяйте всё."*

**Алекс (текстовое сообщение после прощания с Hans):**
> *"Макс. Крылов готовит supply chain attack. Docker Hub легко компрометировать — достаточно одного malicious image. Виктор использует Docker для всех инструментов операции. Если образ скомпрометирован — всё скомпрометировано. Будь параноиком. Проверяй checksums. Сканируй на уязвимости. — A."*

### День 27: Прилёт в Амстердам

**08:00 — Schiphol Airport**

Макс и Дмитрий прилетают в Амстердам. Совершенно другая атмосфера после промышленного Берлина: велосипеды везде, каналы, толерантность, минимализм.

**Дмитрий:**
> *"Амстердам — Docker HQ Europe. Здесь родилась европейская контейнеризация. Sophie работала в Docker Inc. с 2015 по 2020. Если кто-то понимает containers philosophy, это голландцы: pragmatic, minimal, efficient."*

**10:00 — Science Park Amsterdam (Datacenter District)**

Современный технопарк. University of Amsterdam рядом, стартапы, дата-центры. Велосипедные дорожки вместо автомобильных. Очень зелёно.

Sophie van Dijk встречает у входа в datacenter. 32 года, прямая, деловитая, без лишних слов. Голландская прагматичность.

**Sophie:**
> *"Макс, Дмитрий. Добро пожаловать в Амстердам. Виктор сказал, что вам нужно контейнеризировать всё. Отлично. Containers zijn als LEGO — простые блоки, сложные системы. Docker — это не магия. Это просто очень хорошая изоляция. Начнём."*

**10:30 — Datacenter Tour**

Sophie показывает инфраструктуру: ряды серверов с Docker Swarm кластерами, Kubernetes, monitoring dashboards (Grafana + Prometheus).

**Sophie:**
> *"Видишь это? 500 контейнеров работают на 50 серверах. Каждый контейнер — изолированный, воспроизводимый, масштабируемый. Без Docker? 500 VM, 500 копий ОС, огромный overhead. С Docker? Одна ОС, 500 процессов, минимальный overhead. Вот в чём сила."*

**Макс (впечатлён):**
> *"500 контейнеров? На 50 серверах?"*

**Sophie:**
> *"Ja. И мы можем масштабировать до 5000, если нужно. Docker orchestration. Но сначала — basics. Тебе нужно понять контейнеры до orchestration. Пойдём, покажу."*

### 11:00 — Docker Workshop Begins

**Sophie's office:** Минималистичный голландский дизайн. Большие окна, natural light, одно растение, один монитор, mechanical keyboard. Efficiency.

**Sophie:**
> *"Философия Docker простая:
> 1. Build once, run anywhere.
> 2. Изоляция без overhead.
> 3. Воспроизводимые окружения.
> 4. Microservices архитектура.
>
> Операции Виктора нужно всё это. 50 серверов сегодня, 100 завтра. Без контейнеров? Невозможно управлять. С контейнерами? Просто. Покажу тебе Dockerfile."*

(Sophie открывает editor, пишет Dockerfile за 2 минуты)

```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Sophie:**
> *"Четыре строки. Production-ready web server. Alpine base — 5MB. Nginx — 10MB total. Запускается за 1 секунду. Это Docker."*

### ИНЦИДЕНТ (происходит в середине Episode, ~15:30)

**15:30 — Emergency Alert**

Ноутбук Дмитрия начинает пищать. Security alert от системы мониторинга.

**Dmitry (проверяет):**
> *"Чёрт! Sophie, у нас проблема. Один из Docker images Виктора — подозрительная активность. Исходящие соединения к 185.220.101.52 — это Tor exit node Крылова!"*

**Sophie (мгновенно переключается в режим безопасности):**
> *"Какой image? Покажи мне."*

**Дмитрий:**
> *"viktor/crypto-toolkit:latest — мы используем его на 20 серверах!"*

**Sophie:**
> *"Останови все контейнеры СЕЙЧАС. Это supply chain attack. Кто-то запушил скомпрометированный image в ваш registry. Классическая атака на Docker Hub."*

**Max (паника):**
> *"20 серверов скомпрометированы?!"*

**Sophie (спокойно, но быстро):**
> *"Ещё нет. Мы поймали это. Но нам нужно:
> 1. Остановить все контейнеры, использующие этот image
> 2. Просканировать image на malware
> 3. Проверить Docker Hub на компрометацию
> 4. Пересобрать из чистого source
> 5. Проверить checksums
>
> У вас установлен Trivy?"*

**Dmitry:**
> *"Что?"*

**Sophie:**
> *"Trivy. Сканер уязвимостей для контейнеров. Устанавливай. Сейчас."*

#### Emergency Response (15:35 - 16:00)

**Tasks:**

1. **Stop compromised containers:**
```bash
docker ps | grep crypto-toolkit
docker stop $(docker ps -q --filter ancestor=viktor/crypto-toolkit:latest)
```

2. **Scan image with Trivy:**
```bash
trivy image viktor/crypto-toolkit:latest
# Output: CRITICAL: Backdoor detected in /usr/bin/crypto_tool
```

**Sophie:**
> *"Backdoor. Кто-то изменил ваш toolkit. Проверяйте Docker Hub credentials."*

3. **Check Docker Hub:**
```bash
docker history viktor/crypto-toolkit:latest
# Layer 3 pushed by unknown user: "maintenance@viktor-ops.net"
```

**Dmitry:**
> *"Этот email не наш! Кто-то получил доступ к Docker Hub account!"*

**Sophie:**
> *"Меняйте пароль. Отзывайте токены доступа. Удаляйте скомпрометированный image. Пересобирайте из source. И в следующий раз — используйте Docker Content Trust. Цифровые подписи. Этого бы не случилось."*

4. **Rebuild from clean source:**
```bash
git clone https://github.com/viktor-ops/crypto-toolkit
cd crypto-toolkit
docker build -t viktor/crypto-toolkit:v2.0-clean .
docker scan viktor/crypto-toolkit:v2.0-clean  # Clean!
```

5. **Enable Docker Content Trust:**
```bash
export DOCKER_CONTENT_TRUST=1
docker push viktor/crypto-toolkit:v2.0-clean
# Automatically signs image with your key
```

**16:00 — Resolution**

**Sophie:**
> *"Image очищен. Контейнеры перезапущены. Никакой утечки данных. Вам повезло — monitoring поймал это быстро. Но это урок: НИКОГДА не доверяйте Docker images слепо. Всегда сканируйте. Всегда проверяйте. Supply chain attacks реальны."*

**Anna (видеозвонок):**
> *"Forensics завершён. Backdoor был от Крылова. Он скомпрометировал аккаунт Docker Hub через фишинговую атаку на одного из сотрудников Виктора. Повторное использование пароля. Классическая ошибка. Все пароли ротированы. 2FA включён."*

**Alex (текстовое):**
> *"Я предупреждал. Supply chain — самая опасная атака. Хорошо что Sophie знала что делать. — A."*

**Sophie:**
> *"В Нидерландах мы говорим: 'Vertrouwen is goed, controle is beter.' Доверяй, но проверяй. Всегда проверяй. Всегда сканируй. Docker security — не опция."*

### Финал Episode 14

**18:00 — Debriefing**

**Виктор (видеозвонок):**
> *"Crisis averted. Image cleaned. Sophie, thank you. Max, Dmitry — you learned important lesson today. Containers are powerful. But with power comes responsibility. Security first."*

**Sophie:**
> *"Хорошая работа сегодня. Docker basics — готово. Multi-container applications — готово. Security scanning — изучили на горьком опыте. Завтра вы летите обратно в Берлин для CI/CD. Hans научит вас автоматизации. Но помните основы Docker. Всё строится на этом."*

**Dmitry:**
> *"Sophie, спасибо. Ты спасла операцию."*

**Sophie (улыбается):**
> *"Вот что делают Docker architects. Мы строим, защищаем, исправляем. Добро пожаловать в мир контейнеризации. Теперь ты понимаешь, почему Docker изменил мир."*

**Max:**
> *"Containers zijn als LEGO... Теперь понятно."*

**Sophie:**
> *"Goed! Ты учишь голландский. И Docker. Оба полезных навыка."*

**Cliffhanger:**

**Hans (текстовое из Берлина):**
> *"Max, Dmitry. CI/CD pipeline готов в Берлине. Завтра автоматизируем всё. Docker images будут собираться автоматически, тестироваться автоматически, деплоиться автоматически. Но сначала — вы должны понять, что автоматизируете. Увидимся завтра. — Hans"*

---


## 🎯 Миссия Episode 14

**Основная задача:** Контейнеризировать компоненты инфраструктуры операции Виктора, настроить Docker Compose, научиться Docker security.

**Конкретные задания:**

1. ✅ **Install Docker** (Docker Engine + Docker Compose)
2. ✅ **Create Dockerfile** для nginx web server
3. ✅ **Build and run container** (docker build, docker run)
4. ✅ **Docker networking** (bridge, custom networks)
5. ✅ **Docker volumes** (data persistence)
6. ✅ **Multi-stage builds** (optimization, minimal image size)
7. ✅ **Docker Compose** (multi-container: web + database + redis)
8. ✅ **Security scanning** (Trivy для обнаружения уязвимостей)
9. ✅ **INCIDENT: Detect compromised image** (supply chain attack response)

**Финальный артефакт:**
- Рабочие Dockerfiles для всех компонентов
- docker-compose.yml для полного стека
- Security scanning pipeline
- Incident response playbook


---

## 🎓 Учебная программа: 7 циклов

**Продолжительность:** 5-6 часов
**Формат:** Interleaving (Сюжет → Теория → Практика → Проверка)

1. **Цикл 1:** Docker Basics — Контейнеры как LEGO 🧱 (10-15 мин)
2. **Цикл 2:** Images & Dockerfile — Чертежи vs Здания 🏗️ (10-15 мин)
3. **Цикл 3:** Networking — Мосты между островами 🌉 (10-15 мин)
4. **Цикл 4:** Volumes — Долговечное хранилище 💾 (10-15 мин)
5. **Цикл 5:** INCIDENT — Supply Chain Attack 🔥 (15-20 мин)
6. **Цикл 6:** Multi-container (Compose) — Оркестр 🎼 (15-20 мин)
7. **Цикл 7:** Security & Best Practices — Сканирование 🔐 (10-15 мин)

---

## ЦИКЛ 1: Docker Basics — Контейнеры как LEGO 🧱
### (10-15 минут)

### 🎬 Сюжет: Sophie's Introduction

**11:00 — Sophie's office, Science Park Amsterdam**

Sophie открывает терминал, печатает одну команду:

```bash
docker run -d -p 80:80 nginx:alpine
```

Через 2 секунды: веб-сервер работает.

**Sophie:**
> *"Два секунды. Web server готов. На обычной VM? Минимум 5 минут: установка ОС, настройка, установка nginx, конфигурация. С Docker? 2 секунды. Это containers."*

**Max (впечатлён):**
> *"Как это возможно?"*

**Sophie:**
> *"Docker containers zijn als LEGO. Видишь эти кубики LEGO?"*

(показывает на стол с LEGO моделью здания)

> *"Каждый блок — контейнер. Каждый блок делает одну вещь хорошо. Nginx блок — web server. PostgreSQL блок — database. Redis блок — cache. Собираешь из блоков сложные системы. Build once, run anywhere."*

**LILITH:**
> *"LEGO — лучшая метафора для Docker. Маленькие, простые, взаимозаменяемые блоки. Из них строишь что угодно. Сломался блок? Замени. Нужно больше? Добавь копий. Microservices architecture."*

---

### 📚 Теория: Зачем нужен Docker?

**Проблемы без Docker:**
- ❌ "Works on my machine" (разные environments)
- ❌ Dependency hell (библиотеки конфликтуют)
- ❌ Медленный deployment (установка зависимостей каждый раз)
- ❌ Heavyweight VMs (полная ОС для каждого приложения)
- ❌ Сложный scaling (нужно настраивать каждый сервер)

**С Docker:**
- ✅ Воспроизводимые окружения ("works everywhere")
- ✅ Изолированные зависимости (каждый контейнер — своё окружение)
- ✅ Fast deployment (образ уже готов, запуск за секунды)
- ✅ Lightweight (shared OS kernel, minimal overhead)
- ✅ Easy scaling (запустить 100 containers = одна команда)

**LILITH:**
> *"'Works on my machine' — проклятие разработчиков. Docker решает это. Один раз собрал образ — работает везде. Dev, staging, production — одинаково. Магия? Нет. Изоляция."*

---

### 💡 Метафора: Docker = LEGO + Apartments

**Docker как LEGO:**
- **Container** = Один кубик LEGO (модульный, взаимозаменяемый)
- **Image** = Инструкция как собрать кубик
- **Docker Hub** = Магазин LEGO (тысячи готовых блоков)
- **docker-compose** = Инструкция как собрать сложную модель из блоков

**Container как Apartment (квартира):**
```
🏢 Здание (Host OS)
│
├─ 🚪 Apartment 1 (Nginx container)
│   ├─ Isolated (своя кухня, ванна)
│   ├─ Shared (общий фундамент, стены, коммуникации)
│   └─ Port 80 → doorbell
│
├─ 🚪 Apartment 2 (PostgreSQL container)
│   ├─ Isolated (свои жильцы, мебель)
│   ├─ Shared (тот же фундамент)
│   └─ Port 5432 → doorbell
│
└─ 🚪 Apartment 3 (Redis container)
    └─ Isolated + Shared
```

**Почему квартиры, не отдельные дома (VM)?**
- **VM** = Отдельные дома (каждый с фундаментом, стенами, крышей) → дорого, медленно
- **Container** = Квартиры (один фундамент, разделённые стены) → дёшево, быстро

**LILITH:**
> *"Containers — это коммунальная квартира для приложений. Звучит плохо? На самом деле гениально. Shared kernel, isolated processes. Минимальные ресурсы, максимальная эффективность."*

---

### 📖 Containers vs Virtual Machines (Визуализация)

```
┌─────────────────────────────────────┐  ┌─────────────────────────────────────┐
│     Traditional Virtual Machines    │  │         Docker Containers            │
├─────────────────────────────────────┤  ├─────────────────────────────────────┤
│  ┌────────┐ ┌────────┐ ┌────────┐  │  │  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │ App A  │ │ App B  │ │ App C  │  │  │  │ App A  │ │ App B  │ │ App C  │  │
│  ├────────┤ ├────────┤ ├────────┤  │  │  ├────────┤ ├────────┤ ├────────┤  │
│  │ Libs   │ │ Libs   │ │ Libs   │  │  │  │ Libs   │ │ Libs   │ │ Libs   │  │
│  ├────────┤ ├────────┤ ├────────┤  │  │  └────────┘ └────────┘ └────────┘  │
│  │Guest OS│ │Guest OS│ │Guest OS│  │  │           Docker Engine              │
│  └────────┘ └────────┘ └────────┘  │  │  ┌─────────────────────────────────┐ │
│          Hypervisor                 │  │  │         Host OS                 │ │
│  ┌─────────────────────────────────┐ │  │  └─────────────────────────────────┘ │
│  │         Host OS                 │ │  │         Infrastructure               │
│  └─────────────────────────────────┘ │  └─────────────────────────────────────┘
│         Infrastructure              │
└─────────────────────────────────────┘

Heavy: 3 full OS copies                Light: 1 OS, 3 isolated processes
Slow start: 30-60 seconds              Fast start: 1-2 seconds
Large: GB per VM                       Small: MB per container
```

**Sophie:**
> *"Видишь разницу? VM = 3 копии ОС. Docker = 1 ОС, 3 изолированных процесса. Вот почему Docker быстрее и легче."*

---

### 💻 Практика 1: Install Docker & First Container

```bash
# 1. Install Docker (Ubuntu)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# 3. Test installation
docker --version
docker run hello-world

# 4. Run your first real container
docker run -d -p 8080:80 nginx:alpine

# 5. Check it's running
docker ps

# 6. Open browser: http://localhost:8080
# You should see "Welcome to nginx!"

# 7. Stop container
docker stop $(docker ps -q)
```

**Sophie:**
> *"Поздравляю! Ты запустил свой первый контейнер. Nginx работает. Никакой установки, никакой конфигурации. Один docker run. Вот в чём сила."*

---

### 🤔 Проверка понимания: Цикл 1

**LILITH:** *"Проверим основы. Три вопроса."*

**Вопрос 1:** В чём главное отличие Docker от VM?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Shared OS kernel vs отдельные ОС.**

- **VM:** Каждая VM = полная ОС (kernel + userspace) → тяжело, медленно
- **Docker:** Все containers = один kernel (host OS), изолированные userspace → легко, быстро

**LILITH:** *"VM — как отдельные дома. Docker — как квартиры в одном доме. Shared infrastructure, isolated living."*

</details>

**Вопрос 2:** Почему Docker containers запускаются за секунды?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Не нужно загружать ОС!

- **VM:** Загрузка ОС (BIOS, bootloader, kernel, init) → 30-60 секунд
- **Docker:** Просто запуск процесса (OS уже работает) → 1-2 секунды

**Image уже готов** — все зависимости включены, не нужно устанавливать.

**Sophie:** *"Container — это просто процесс. Процесс запускается мгновенно. Вот и всё."*

</details>

**Вопрос 3:** Что означает "Build once, run anywhere"?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Docker image работает везде одинаково.**

Собрал образ на laptop → запускается на:
- Dev сервере
- Staging сервере
- Production сервере
- AWS, Azure, Google Cloud
- Любой Linux с Docker

**Одинаковое поведение везде.** Никаких "works on my machine" проблем.

**LILITH:** *"Docker — это shipping container для приложений. Грузишь в контейнер → везёшь куда угодно → работает одинаково. Вот и вся магия."*

</details>

**Sophie:**
> *"Отлично. Docker basics понятны. Теперь глубже — как создать свой образ."*

---


## ЦИКЛ 2: Images & Dockerfile — Чертежи vs Здания 🏗️
### (10-15 минут)

### 🎬 Сюжет: Sophie объясняет Images

**11:30 — Sophie's office**

Sophie рисует на whiteboard:

```
Image (blueprint) → docker build → Image file
      ↓
docker run → Container (running building)
```

**Sophie:**
> *"Image — это чертёж. Container — это построенное здание. Из одного чертежа можешь построить 100 зданий. Dockerfile — это инструкция как нарисовать чертёж."*

**Max:**
> *"Где берутся images? Docker Hub?"*

**Sophie:**
> *"Ja. Docker Hub — это GitHub для образов. Тысячи готовых images: nginx, postgres, redis, python, node. Но ты также можешь создать свой. Покажу."*

(Sophie пишет Dockerfile за 3 минуты)

```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Sophie:**
> *"Четыре строки. Production-ready web server. Соб

ираем: `docker build -t my-web .` — готово. Запускаем: `docker run my-web` — работает. Build once, run anywhere."*

**LILITH:**
> *"Dockerfile — это рецепт для повара. FROM = основа блюда. COPY = добавить ингредиенты. CMD = как подавать. Следуй рецепту — получишь одинаковое блюдо каждый раз."*

---

### 📚 Теория: Image vs Container

**Метафора: Blueprint vs Building**

```
📐 Image (blueprint)          🏢 Container (building)
├─ Static (не меняется)       ├─ Dynamic (работает, меняется)
├─ Template                   ├─ Instance
├─ Read-only                  ├─ Read-write
├─ Можно делиться             ├─ Локальный
└─ Один image → N containers  └─ Удалили container — image остался
```

**Пример:**

```bash
# Image nginx:alpine — чертёж здания
docker pull nginx:alpine

# Создать 3 containers из одного image
docker run -d --name web1 nginx:alpine
docker run -d --name web2 nginx:alpine
docker run -d --name web3 nginx:alpine

# Результат: 3 running containers, 1 image
docker ps        # 3 containers
docker images    # 1 image (nginx:alpine)
```

**Sophie:**
> *"Один чертёж, три здания. Все одинаковые. Это Docker."*

**LILITH:**
> *"Image — это класс в ООП. Container — это объект. Из одного класса создаёшь множество объектов. Docker = ООП для инфраструктуры."*

---

### 📖 Dockerfile Anatomy

**Dockerfile = рецепт для создания image.**

```dockerfile
# FROM: база (parent image)
FROM python:3.11-alpine

# WORKDIR: рабочая директория (cd)
WORKDIR /app

# COPY: копировать файлы из host → image
COPY requirements.txt .
COPY app.py .

# RUN: выполнить команду во время BUILD
RUN pip install -r requirements.txt

# EXPOSE: документация какой порт использует
EXPOSE 5000

# CMD: команда при START контейнера
CMD ["python", "app.py"]
```

**Ключевые инструкции:**

| Инструкция | Когда выполняется | Назначение |
|------------|-------------------|------------|
| `FROM` | Build | Базовый image |
| `RUN` | Build | Установка зависимостей |
| `COPY` | Build | Копирование файлов |
| `EXPOSE` | Documentation | Какой порт |
| `CMD` | Runtime | Команда запуска |
| `ENV` | Build/Runtime | Environment переменные |
| `WORKDIR` | Build/Runtime | Рабочая директория |

**LILITH:**
> *"FROM — фундамент. RUN — строительство. CMD — запуск. Dockerfile — это история создания образа. От фундамента до крыши."*

---

### 💡 "Aha!" момент: Layers (слои)

**Docker image = stack of layers** (как слоёный пирог).

```
┌──────────────────────────┐
│  CMD ["python", "app.py"]│  ← Layer 5 (1 KB)
├──────────────────────────┤
│  COPY app.py .           │  ← Layer 4 (10 KB)
├──────────────────────────┤
│  RUN pip install ...     │  ← Layer 3 (50 MB)
├──────────────────────────┤
│  COPY requirements.txt   │  ← Layer 2 (1 KB)
├──────────────────────────┤
│  FROM python:3.11-alpine │  ← Layer 1 (base, 50 MB)
└──────────────────────────┘
Total size: ~100 MB
```

**Почему layers важны?**

**Caching:** Docker кэширует каждый layer.

```dockerfile
# ❌ ПЛОХО: app.py меняется часто, весь layer пересобирается
COPY . .
RUN pip install -r requirements.txt

# ✅ ХОРОШО: requirements.txt меняется редко, кэш работает
COPY requirements.txt .
RUN pip install -r requirements.txt  # Cached!
COPY app.py .  # Только это пересобирается
```

**Пример:**

```bash
# First build: 2 минуты (скачивает все зависимости)
docker build -t myapp .

# Change app.py, rebuild: 5 секунд (кэш!)
docker build -t myapp .
```

**Sophie:**
> *"Layers + caching = быстрые builds. Редко меняющиеся вещи (requirements) — в начало. Часто меняющиеся (app.py) — в конец. Оптимизация."*

**LILITH:**
> *"Docker слои — как коммиты в Git. Каждый Dockerfile instruction = новый commit. Git кэширует commits. Docker кэширует layers. Понял параллель?"*

---

### 💻 Практика 2: Create Custom Dockerfile

```bash
cd ~/kernel-shadows/season-4-devops-automation/episode-14-docker-basics/starter

# 1. Look at starter/Dockerfile (has TODO comments)
cat Dockerfile

# 2. Fill TODO sections:
# - FROM: choose base image (nginx:alpine recommended)
# - COPY: add your nginx.conf and html files
# - EXPOSE: port 80
# - CMD: start nginx

# 3. Build image
docker build -t operation-shadow-web .

# 4. Run container
docker run -d -p 8080:80 --name web operation-shadow-web

# 5. Test
curl http://localhost:8080

# 6. Check logs
docker logs web

# 7. Stop and remove
docker stop web
docker rm web
```

**Sophie:**
> *"Твой первый custom image. Теперь можешь деплоить этот образ на любой сервер с Docker. Build once, run anywhere."*

---

### 🤔 Проверка понимания: Цикл 2

**LILITH:** *"Images и layers — ключевые концепты. Три вопроса."*

**Вопрос 1:** Что произойдёт если удалить container? Image тоже удалится?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **НЕТ!** Image остаётся.

```bash
docker run -d --name web nginx:alpine  # Create container
docker stop web
docker rm web    # Delete container
docker images    # nginx:alpine STILL HERE!
```

**Image** = template (остаётся)
**Container** = instance (удалён)

Можно снова создать container из того же image.

**LILITH:** *"Снёс здание — чертёж остался. Из чертежа можешь построить новое здание."*

</details>

**Вопрос 2:** Зачем порядок инструкций в Dockerfile важен?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Layer caching!**

```dockerfile
# ❌ ПЛОХО: app.py меняется часто, весь RUN пересобирается
COPY app.py .
RUN pip install expensive-package  # 5 минут!
# Change app.py → rebuild = 5 минут снова

# ✅ ХОРОШО: requirements редко меняется, кэш работает
COPY requirements.txt .
RUN pip install -r requirements.txt  # Cached!
COPY app.py .  # Only this rebuilds (1 секунда)
```

**Правило:** Редко меняющееся — наверх. Часто меняющееся — вниз.

**Sophie:** *"Optimization. Порядок имеет значение."*

</details>

**Вопрос 3:** Сколько containers можно создать из одного image?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Unlimited!**

```bash
# Один image
docker pull nginx:alpine

# Создать 100 containers
for i in {1..100}; do
  docker run -d --name web$i nginx:alpine
done

# Результат: 100 running containers, 1 image
```

**Image** = template (можно переиспользовать бесконечно)

**Это основа scaling:** запустить 100 копий приложения = одна команда.

**LILITH:** *"Один чертёж, бесконечные здания. Вот почему Docker масштабируется так легко."*

</details>

**Sophie:**
> *"Goed! Теперь ты понимаешь images. Следующее: как containers общаются?"*

---


## ЦИКЛ 3: Networking — Мосты между островами 🌉
### (10-15 минут)

### 🎬 Сюжет: Connecting Containers

**12:00 — После обеда**

**Dmitry:**
> *"Sophie, вопрос. Если каждый container изолирован... как они общаются? Web server нужен доступ к database."*

**Sophie (рисует на доске):**

```
[Web Container] ←→ ??? ←→ [DB Container]
```

> *"Docker networks. Containers как острова. Network — это мост между ними. Без моста — изоляция. С мостом — связь."*

**Max:**
> *"Как в Amsterdam — каналы и мосты везде!"*

**Sophie (улыбается):**
> *"Exact! Амстердам — 165 каналов, 1500 мостов. Docker — та же идея. Каналы = networks, мосты = connections. Pragmatic Dutch engineering."*

**LILITH:**
> *"Networking — это артерии инфраструктуры. Без networking контейнеры мертвы. С networking — ecosystem."*

---

### 📚 Теория: Docker Networks

**Containers изолированы по умолчанию.**

```bash
# Container 1: isolated
docker run -d --name web nginx

# Container 2: isolated
docker run -d --name db postgres

# Web НЕ МОЖЕТ подключиться к DB!
# Different network namespaces
```

**Решение: Docker Networks**

```bash
# Create custom network
docker network create app-network

# Connect containers to network
docker run -d --name web --network app-network nginx
docker run -d --name db --network app-network postgres

# Now web CAN connect to db!
# Inside web container:
curl http://db:5432  # Works! DNS resolution automatic
```

---

### 📖 Docker Network Types

| Type | Use Case | Isolation |
|------|----------|-----------|
| `bridge` | Single host (default) | Containers on same host |
| `host` | No isolation (share host network) | No isolation |
| `none` | Complete isolation | No network |
| `overlay` | Multi-host (Swarm/Kubernetes) | Containers across hosts |

**Default network:**

```bash
docker run nginx  # Автоматически в "bridge" network
```

**Custom network (recommended):**

```bash
docker network create my-network
docker run --network my-network nginx
```

**Почему custom networks лучше?**

✅ **Automatic DNS:** Containers видят друг друга по имени
✅ **Isolation:** Другие containers не попадают в твою сеть
✅ **Control:** Ты управляешь кто с кем может говорить

**LILITH:**
> *"Default bridge — как общая Wi-Fi в кафе. Custom network — как частная VPN. Какую выберешь для production?"*

---

### 💡 Метафора: Networks = Bridges in Amsterdam

```
🏝️ Island 1 (Web Container)
        │
        🌉 Bridge (Docker Network)
        │
🏝️ Island 2 (DB Container)
        │
        🌉 Bridge (Docker Network)
        │
🏝️ Island 3 (Redis Container)
```

**No bridge:** Islands isolated (secure, but useless)
**With bridges:** Islands connected (communication!)

**Sophie:**
> *"In Amsterdam, без мостов город не работает. В Docker, без networks приложение не работает. Same principle."*

---

### 💻 Практика 3: Docker Networking

```bash
# 1. Create custom network
docker network create operation-shadow-net

# 2. Run database on network
docker run -d \
  --name db \
  --network operation-shadow-net \
  -e POSTGRES_PASSWORD=secret \
  postgres:alpine

# 3. Run web app on same network
docker run -d \
  --name web \
  --network operation-shadow-net \
  -p 8080:80 \
  nginx:alpine

# 4. Test connectivity (exec into web container)
docker exec web ping db  # Works! DNS resolution

# 5. Inspect network
docker network inspect operation-shadow-net

# 6. Disconnect/reconnect
docker network disconnect operation-shadow-net web
docker network connect operation-shadow-net web

# 7. Cleanup
docker stop web db
docker rm web db
docker network rm operation-shadow-net
```

---

### 🤔 Проверка понимания: Цикл 3

**Вопрос 1:** Как containers общаются в custom network?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **По имени контейнера (DNS resolution).**

```bash
docker network create mynet
docker run -d --name db --network mynet postgres
docker run -d --name web --network mynet nginx

# Inside web container:
ping db          # Works! Resolved to db's IP
curl http://db:5432  # Connect to database
```

Docker автоматически настраивает DNS для custom networks.

**LILITH:** *"Docker networks — как телефонная книга. Знаешь имя (db) → Docker даёт номер (IP). Звонишь."*

</details>

**Вопрос 2:** Почему не использовать `--link` (legacy)?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Deprecated!** Custom networks лучше.

```bash
# ❌ OLD WAY (deprecated):
docker run --link db nginx

# ✅ NEW WAY:
docker network create mynet
docker run --network mynet db
docker run --network mynet nginx
```

**Custom networks:**
- ✅ Automatic DNS
- ✅ Better isolation
- ✅ Works with docker-compose
- ✅ Not deprecated

**Sophie:** *"--link is from 2014. This is 2025. Use custom networks."*

</details>

---

## ЦИКЛ 4: Volumes — Долговечное хранилище 💾
### (10-15 минут)

### 🎬 Сюжет: Data Persistence Problem

**13:00 — Sophie демонстрирует проблему**

```bash
# Start postgres container
docker run -d --name db -e POSTGRES_PASSWORD=secret postgres

# Create database
docker exec db psql -U postgres -c "CREATE DATABASE mydata;"

# Stop and remove container
docker stop db
docker rm db

# Start new container
docker run -d --name db -e POSTGRES_PASSWORD=secret postgres

# Database gone! 💀
docker exec db psql -U postgres -c "\l"  # mydata NOT THERE
```

**Max:**
> *"Данные исчезли?!"*

**Sophie:**
> *"Ja. Container = ephemeral (временный). Удалил container → данные ушли. Нужен volume."*

**LILITH:**
> *"Container — это бумажный стаканчик. Использовал, выбросил. Volume — это термос. Можешь менять стаканчики, но кофе (данные) остаётся в термосе."*

---

### 📚 Теория: Docker Volumes

**Problem:** Container filesystem is ephemeral.

```bash
docker run nginx
# Write files inside container
docker exec nginx sh -c "echo data > /tmp/file.txt"

# Remove container
docker rm -f nginx

# Data GONE! 💀
```

**Solution:** Docker Volumes (persistent storage)

```bash
docker volume create mydata
docker run -v mydata:/data nginx

# Write to volume
docker exec nginx sh -c "echo data > /data/file.txt"

# Remove container
docker rm -f nginx

# Start new container with same volume
docker run -v mydata:/data nginx

# Data STILL THERE! ✅
docker exec nginx cat /data/file.txt  # "data"
```

---

### 📖 Volume Types

**1. Named Volume (recommended)**

```bash
docker volume create mydata
docker run -v mydata:/app/data nginx
```

✅ Managed by Docker
✅ Portable
✅ Best practice

**2. Bind Mount (host directory)**

```bash
docker run -v /host/path:/container/path nginx
```

✅ Development (live code changes)
❌ Not portable (depends on host path)

**3. tmpfs (RAM only, temporary)**

```bash
docker run --tmpfs /app/cache nginx
```

✅ Fast (RAM)
❌ Ephemeral (gone on stop)

---

### 💡 "Aha!" момент: Volumes persist!

**Без volume:**

```bash
docker run --name db postgres
# Add data
docker exec db createdb mydata
docker stop db
docker rm db

# Start new container
docker run --name db postgres
# Data GONE! 💀
```

**С volume:**

```bash
docker volume create pgdata
docker run --name db -v pgdata:/var/lib/postgresql/data postgres
# Add data
docker exec db createdb mydata
docker stop db
docker rm db

# Start new container with SAME volume
docker run --name db -v pgdata:/var/lib/postgresql/data postgres
# Data STILL HERE! ✅
```

**Sophie:**
> *"Volume — это SSD, который можно перемещать между containers. Container умер? Volume жив. Attach к новому контейнеру."*

**LILITH:**
> *"Volumes — это бессмертие для данных. Containers временны. Volumes вечны. Ну, пока не сделаешь `docker volume rm`."*

---

### 💻 Практика 4: Persistent Database

```bash
# 1. Create volume for database
docker volume create operation-shadow-db

# 2. Run PostgreSQL with volume
docker run -d \
  --name db \
  -v operation-shadow-db:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:alpine

# 3. Create database
docker exec db psql -U postgres -c "CREATE DATABASE ops;"

# 4. Add data
docker exec db psql -U postgres -d ops -c "CREATE TABLE agents (name TEXT);"
docker exec db psql -U postgres -d ops -c "INSERT INTO agents VALUES ('Max');"

# 5. Stop and REMOVE container
docker stop db
docker rm db

# 6. Start NEW container with SAME volume
docker run -d \
  --name db-new \
  -v operation-shadow-db:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:alpine

# 7. Check data — STILL THERE!
docker exec db-new psql -U postgres -d ops -c "SELECT * FROM agents;"
# Output: Max ✅

# 8. List volumes
docker volume ls

# 9. Inspect volume
docker volume inspect operation-shadow-db
```

**Sophie:**
> *"Data survived container death. This is volumes."*

---

### 🤔 Проверка понимания: Цикл 4

**Вопрос 1:** Что произойдёт с данными если удалить container?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Зависит от того, есть ли volume!**

**БЕЗ volume:**
```bash
docker run --name db postgres
docker rm db  # Data GONE! 💀
```

**С volume:**
```bash
docker run --name db -v mydata:/var/lib/postgresql/data postgres
docker rm db  # Container gone, but volume (data) REMAINS! ✅
```

Volume продолжает существовать после удаления контейнера.

**LILITH:** *"Container — это арендованная квартира. Съехал — квартира пуста. Volume — это сейф в банке. Квартиру сдал, сейф остался."*

</details>

**Вопрос 2:** Когда использовать bind mount vs named volume?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:**

**Bind mount (host directory):** Development
```bash
# Live code changes (edit on host → reflected in container)
docker run -v $(pwd)/src:/app/src node
```

**Named volume:** Production
```bash
# Managed by Docker, portable, proper lifecycle
docker volume create dbdata
docker run -v dbdata:/var/lib/postgresql/data postgres
```

**Rule:** Development = bind mount. Production = named volume.

**Sophie:** *"Bind mount для dev (хочешь видеть файлы). Named volume для prod (Docker manages)."*

</details>

**Вопрос 3:** Можно ли подключить один volume к нескольким containers?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **ДА!** (с осторожностью)

```bash
docker volume create shared

# Container 1: write
docker run -v shared:/data alpine sh -c "echo hello > /data/file.txt"

# Container 2: read
docker run -v shared:/data alpine cat /data/file.txt
# Output: hello ✅
```

**Use cases:**
- Shared configuration
- Log aggregation
- Data processing pipelines

**Warning:** Если оба пишут одновременно → race conditions! Нужна синхронизация.

**LILITH:** *"Shared volume — как shared Google Drive. Многие могут читать. Но если все пишут одновременно — хаос. Нужен coordination."*

</details>

---


## ЦИКЛ 5: INCIDENT — Supply Chain Attack 🔥🚨
### (15-20 минут)

### 🎬 Сюжет: Emergency Alert

**15:30 — Alarm!**

Dmitry's laptop начинает пищать. Red alert на экране.

**Dmitry (проверяет monitoring):**
> *"Чёрт! Sophie! У нас проблема!"*

**Sophie (мгновенно серьёзная):**
> *"Покажи."*

**Dmitry (показывает экран):**
> *"viktor/crypto-toolkit:latest — подозрительная активность. Исходящие соединения к 185.220.101.52!"*

**Sophie (смотрит на IP):**
> *"Tor exit node. Русский. Это Крылов?"*

**Max (проверяет notes от Alex):**
> *"Да! Alex предупреждал! Supply chain attack на Docker images!"*

**Sophie (уже печатает команды):**
> *"Сколько серверов используют этот image?"*

**Dmitry:**
> *"20 production серверов!"*

**Sophie:**
> *"Scheisse. Останавливаем ВСЁ. СЕЙЧАС."*

**LILITH:**
> *"Это не drill. Это real incident. Один скомпрометированный image = вся инфраструктура под угрозой. Supply chain — самая опасная атака."*

---

### 📚 Теория: Supply Chain Attacks

**Что это?**

Атака на цепочку поставки (supply chain) — компрометация доверенного источника.

**В Docker:**

```
Developer → Pushes image → Docker Hub → You pull image → COMPROMISED!
                ↑
         Attacker injects malware
```

**Real world examples:**

1. **2021: codecov bash uploader**
   - Скомпрометирован bash script
   - Использовался тысячами компаний
   - Stolen credentials, source code

2. **2020: SolarWinds**
   - Trojan в software update
   - 18,000+ organizations compromised
   - $100M+ damage

3. **Docker Hub compromise (this episode):**
   - Attacker gets Docker Hub credentials
   - Pushes malicious image
   - Operations pull compromised image

---

### 📖 Attack Vector: Compromised Image

**How it works:**

```
1. Attacker compromises Docker Hub account (phishing, password reuse)
   ↓
2. Pushes malicious layer to existing image
   ↓
3. Victims pull "trusted" image
   ↓
4. Backdoor runs in production
   ↓
5. Data exfiltration, crypto mining, botnet, etc.
```

**Why it's dangerous:**

✅ **Trust:** You trust official images
✅ **Scale:** One compromised image → thousands of servers
✅ **Persistence:** Image persists even after removal from Hub
✅ **Stealth:** Malware in layer, hard to detect

**LILITH:**
> *"Supply chain атака — это отравление воды в источнике. Все кто пьют — заражены. Docker Hub — источник. Образ — вода. Check your water."*

---

### 🔥 Emergency Response (15:35 - 16:00)

**Sophie's Incident Response Protocol:**

#### Phase 1: STOP (2 минуты)

```bash
# 1. Find all containers using compromised image
docker ps | grep viktor/crypto-toolkit

# 2. Stop ALL immediately
docker stop $(docker ps -q --filter ancestor=viktor/crypto-toolkit:latest)

# 3. Verify stopped
docker ps  # Should be empty for crypto-toolkit
```

**Sophie:**
> *"Stopped. Breach contained. Now analysis."*

---

#### Phase 2: SCAN (5 минут)

```bash
# Install Trivy (vulnerability scanner)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh

# Scan compromised image
trivy image viktor/crypto-toolkit:latest

# OUTPUT:
# CRITICAL: Backdoor detected in /usr/bin/crypto_tool
# HIGH: Suspicious outbound connection to 185.220.101.52
# MEDIUM: Unverified GPG signatures
```

**Dmitry:**
> *"Backdoor подтверждён!"*

**Sophie:**
> *"Forensics. Check history."*

```bash
# Inspect image layers
docker history viktor/crypto-toolkit:latest

# OUTPUT:
# Layer 3 (added 2 days ago) by "maintenance@viktor-ops.net"
# ↑ SUSPICIOUS! This email is NOT yours
```

**Max:**
> *"Этот email не наш!"*

**Sophie:**
> *"Docker Hub account compromised. Кто-то получил доступ."*

---

#### Phase 3: INVESTIGATE (3 минуты)

**Anna (joins video call):**
> *"Forensics started. Checking Docker Hub logs... Found it! Phishing attack на junior dev. Password reuse. Attacker got Docker Hub token."*

**Sophie:**
> *"Classic. How long ago?"*

**Anna:**
> *"48 hours. Malicious layer pushed 47 hours ago. 20 servers pulled it."*

**Dmitry:**
> *"Какие данные украдены?"*

**Anna (проверяет):**
> *"Мониторинг показывает — connections к Tor node, но data exfiltration не detected. We caught it early."*

**LILITH:**
> *"Повезло. Мониторинг поймал это до утечки. В следующий раз можете не успеть. Prevention > detection."*

---

#### Phase 4: REMEDIATION (10 минут)

**Sophie's checklist:**

```bash
# 1. Rotate ALL Docker Hub credentials
# (do this in Docker Hub UI)

# 2. Enable 2FA
echo "2FA ENABLED on Docker Hub account" ✅

# 3. Delete compromised image
docker rmi viktor/crypto-toolkit:latest

# 4. Rebuild from CLEAN source
git clone https://github.com/viktor-ops/crypto-toolkit
cd crypto-toolkit
docker build -t viktor/crypto-toolkit:v2.0-clean .

# 5. Scan NEW image
trivy image viktor/crypto-toolkit:v2.0-clean
# Result: No vulnerabilities ✅

# 6. Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1
docker push viktor/crypto-toolkit:v2.0-clean
# Image now SIGNED with your GPG key

# 7. Deploy clean image
for server in $(cat servers.txt); do
  ssh $server "docker pull viktor/crypto-toolkit:v2.0-clean"
  ssh $server "docker run -d viktor/crypto-toolkit:v2.0-clean"
done
```

**16:00 — Resolution**

**Sophie:**
> *"Done. 20 servers cleaned. New image signed. Monitoring shows no suspicious activity."*

**Anna:**
> *"Forensics complete. No data breach. Все пароли ротированы. 2FA включён. Attacker blocked."*

**Alex (текст):**
> *"Я предупреждал. Supply chain — самый опасный вектор. Хорошо что Sophie знала что делать. — A."*

---

### 📋 Post-Incident: Prevention Measures

**Sophie's Security Checklist:**

#### 1. Docker Content Trust (DCT)

```bash
# Enable image signing
export DOCKER_CONTENT_TRUST=1

# Now docker pull ONLY accepts signed images
docker pull unsigned-image  # ❌ FAIL
docker pull signed-image    # ✅ OK (verified signature)
```

#### 2. Image Scanning Pipeline

```bash
# Add to CI/CD:
trivy image my-image:latest || exit 1

# Before deployment:
docker scan my-image:latest
```

#### 3. Private Registry

```bash
# Don't rely on Docker Hub
# Host your own registry
docker run -d -p 5000:5000 registry:2

# Push only to your registry
docker tag my-image localhost:5000/my-image
docker push localhost:5000/my-image
```

#### 4. Minimal Base Images

```bash
# ❌ DON'T: ubuntu:latest (1GB, hundreds of packages)
FROM ubuntu:latest

# ✅ DO: alpine (5MB, minimal packages)
FROM alpine:latest

# ✅ EVEN BETTER: distroless (no shell, no package manager)
FROM gcr.io/distroless/static
```

#### 5. Regular Audits

```bash
# Weekly scan all images
docker images -q | xargs -I {} trivy image {}

# Check for outdated images
docker images --format "{{.Repository}}:{{.Tag}}" | xargs -I {} docker pull {}
```

**Sophie:**
> *"Security is not one-time. Security is process. Scan regularly. Update regularly. Monitor always."*

**LILITH:**
> *"Security в DevOps — это гигиена. Чистишь зубы каждый день, не раз в год. Сканируй images каждый день. Обновляй dependencies. Monitor logs. Паранойя — это профессионализм."*

---

### 🤔 Проверка понимания: Цикл 5

**LILITH:** *"Incident разобран. Critical вопросы."*

**Вопрос 1:** Почему нельзя просто удалить compromised image? Проблема решена?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **НЕТ! Недостаточно.**

```bash
docker rmi compromised-image  # Image deleted locally
# But:
# - Image still exists on servers that pulled it!
# - Attacker still has Docker Hub access!
# - No new image deployed!
```

**Нужно:**
1. Stop всех containers с этим image
2. Delete image везде
3. Rotate credentials (Docker Hub, secrets)
4. Rebuild from clean source
5. Scan new image
6. Deploy clean image
7. Enable DCT (prevent future)

**Sophie:** *"Deleting image — это 10% работы. Full remediation = checklist."*

</details>

**Вопрос 2:** Как Docker Content Trust защищает от supply chain attacks?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Cryptographic signatures.**

```bash
export DOCKER_CONTENT_TRUST=1

# When you push:
docker push my-image
# Docker signs image with your private key

# When someone pulls:
docker pull my-image
# Docker verifies signature with your public key
# If signature invalid or missing → FAIL
```

**Защита:**
- ✅ Attacker can't push fake image (no your private key)
- ✅ Man-in-the-middle attack prevented (signature verification)
- ✅ Only YOU can push signed images

**LILITH:** *"DCT — это GPG для Docker. Подписываешь image своим ключом. Другие проверяют подпись. Fake image не пройдёт проверку."*

</details>

**Вопрос 3:** Сколько времени есть на реакцию после compromise?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **< 30 минут для критических данных.**

**Real-world timeline:**
- **0-15 мин:** Compromise detected
- **15-30 мин:** Incident response (stop, scan, rebuild)
- **30-60 мин:** Full remediation
- **After 60 мин:** Возможна data exfiltration

**В этом episode:**
- 30 мин после compromise: detected
- 25 мин response: incident resolved
- Total: 55 минут (успели!)

**Anna:** *"Если бы мониторинг не поймал — могли потерять всё. Fast detection = critical."*

**LILITH:** *"В security счёт идёт на минуты. Не часы. Не дни. Минуты. Slow response = compromised operation."*

</details>

**Sophie:**
> *"Вот почему я параноик. Вот почему scanning обязателен. Вот почему Docker security не опция. One compromised image = вся операция под угрозой."*

**Max:**
> *"Понял. Теперь буду сканировать всё. Trivy, DCT, private registry. Всё."*

**Sophie:**
> *"Goed. Теперь давай покажу как правильно деплоить multiple containers. Docker Compose."*

---


## ЦИКЛ 6: Multi-container (Compose) — Оркестр 🎼
### (15-20 минут)

### 🎬 Сюжет: After Incident

**16:30 — Напряжение спало**

**Sophie (делает глубокий вдох):**
> *"Crisis averted. Теперь правильный способ: docker-compose. Multi-container applications made easy."*

**Max:**
> *"Docker Compose — это что?"*

**Sophie (рисует схему):**

```
docker run web    \
docker run db     |→ Много команд, сложно
docker run redis  |
docker run cache  /

vs

docker-compose up → Одна команда!
```

> *"Docker Compose — это оркестровка. Conductor управляет оркестром. Compose управляет containers."*

**LILITH:**
> *"Compose — это дирижёр оркестра. Каждый контейнер — музыкант. Без дирижёра — хаос. С дирижёром — симфония."*

---

### 📚 Теория: Docker Compose

**Problem: Managing multiple containers manually = pain**

```bash
# Without Compose: many commands
docker network create mynet
docker run -d --name db --network mynet postgres
docker run -d --name redis --network mynet redis
docker run -d --name web --network mynet -p 80:80 nginx
docker run -d --name api --network mynet -p 8080:8080 api-server
```

**Solution: Docker Compose**

```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    image: nginx
    ports:
      - "80:80"
  db:
    image: postgres
  redis:
    image: redis
  api:
    image: api-server
    ports:
      - "8080:8080"
```

```bash
# One command to rule them all:
docker-compose up
```

✅ Automatic network creation
✅ Dependency management
✅ Environment variables
✅ Volume management
✅ Easy scaling

**Sophie:**
> *"Compose превращает 20 команд в одну. Это efficiency."*

---

### 💡 Метафора: Compose = Orchestra Conductor

```
🎼 Conductor (docker-compose)
    │
    ├─ 🎻 Violinist (web container)
    │   Play on port 80!
    │
    ├─ 🎺 Trumpeter (database container)
    │   Play on port 5432!
    │
    ├─ 🥁 Drummer (redis container)
    │   Play on port 6379!
    │
    └─ 🎹 Pianist (api container)
        Play on port 8080!
```

**Without conductor:** Each musician plays alone → cacophony
**With conductor:** Synchronized → symphony!

**LILITH:**
> *"docker-compose.yml — это ноты. `docker-compose up` — начало концерта. All services start in harmony."*

---

### 📖 docker-compose.yml Anatomy

```yaml
version: '3.8'  # Compose file format version

services:  # List of containers

  web:  # Service name (becomes hostname in network)
    image: nginx:alpine  # Docker image to use
    ports:
      - "8080:80"  # Host:Container port mapping
    volumes:
      - ./html:/usr/share/nginx/html  # Bind mount
    networks:
      - frontend  # Custom network
    depends_on:
      - api  # Start api before web
    environment:
      - ENV=production  # Environment variables
    restart: always  # Restart policy
  
  api:
    build: ./api  # Build from Dockerfile in ./api
    ports:
      - "3000:3000"
    networks:
      - frontend
      - backend
    depends_on:
      - db
    env_file:
      - .env  # Load env vars from file
  
  db:
    image: postgres:alpine
    volumes:
      - db-data:/var/lib/postgresql/data  # Named volume
    networks:
      - backend
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: appdb

networks:  # Custom networks
  frontend:
  backend:

volumes:  # Named volumes
  db-data:
```

**Sophie:**
> *"Everything in one file. Version controlled. Reproducible. Dit is the way."*

---

### 💻 Практика 6: Multi-container Stack

```bash
cd ~/kernel-shadows/season-4-devops-automation/episode-14-docker-basics/starter

# 1. Look at docker-compose.yml (has TODO comments)
cat docker-compose.yml

# 2. Fill TODO sections for:
# - web service (nginx)
# - db service (postgres)
# - redis service (redis)

# 3. Start entire stack
docker-compose up -d

# 4. Check all services running
docker-compose ps

# 5. View logs
docker-compose logs -f web

# 6. Execute command in service
docker-compose exec web sh

# 7. Scale service (run 3 copies of web)
docker-compose up -d --scale web=3

# 8. Stop all services
docker-compose down

# 9. Stop and remove volumes
docker-compose down -v
```

**Common commands:**

```bash
docker-compose up              # Start services (foreground)
docker-compose up -d           # Start services (background)
docker-compose down            # Stop and remove containers
docker-compose ps              # List services
docker-compose logs            # View logs
docker-compose exec web bash  # Run command in service
docker-compose build           # Rebuild images
docker-compose restart         # Restart services
```

---

### 💡 "Aha!" момент: Compose simplicity

**Manual way (10 commands):**

```bash
docker network create app-net
docker volume create db-data
docker run -d --name db --network app-net -v db-data:/var/lib/postgresql/data -e POSTGRES_PASSWORD=secret postgres
docker run -d --name redis --network app-net redis
docker run -d --name web --network app-net -p 80:80 nginx
```

**Compose way (1 command):**

```yaml
# docker-compose.yml
services:
  web:
    image: nginx
    ports: ["80:80"]
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - db-data:/var/lib/postgresql/data
  redis:
    image: redis

volumes:
  db-data:
```

```bash
docker-compose up -d  # Done!
```

**Sophie:**
> *"10 commands vs 1. This is why we use Compose. Simplicity."*

**LILITH:**
> *"Compose — это automation. Computers хороши в automation. Humans плохи в typing 10 команд без ошибок. Let Compose do the boring work."*

---

### 🤔 Проверка понимания: Цикл 6

**Вопрос 1:** Нужно ли создавать network вручную при использовании Compose?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **НЕТ! Compose создаёт автоматически.**

```yaml
# docker-compose.yml
services:
  web:
    image: nginx
  db:
    image: postgres
```

```bash
docker-compose up
# Compose automatically creates:
# - Network: "myproject_default"
# - Containers can communicate by service name (web, db)
```

**Custom network (optional):**

```yaml
services:
  web:
    networks:
      - frontend
networks:
  frontend:  # Custom network name
```

**Sophie:** *"Compose handles networking. You just describe what you want."*

</details>

**Вопрос 2:** Что делает `depends_on`?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Контролирует порядок запуска.**

```yaml
services:
  web:
    depends_on:
      - db  # Start db BEFORE web
  db:
    image: postgres
```

```bash
docker-compose up
# Order: 1) db starts, 2) web starts
```

**Warning:** `depends_on` запускает в порядке, но **НЕ ждёт готовности!**

```yaml
# ❌ NOT GUARANTEED:
# db may still be initializing when web starts

# ✅ BETTER: Add health check
services:
  db:
    healthcheck:
      test: pg_isready -U postgres
  web:
    depends_on:
      db:
        condition: service_healthy
```

**LILITH:** *"`depends_on` — это like saying 'start engine before driving'. Но engine может ещё греться. Health check = wait until engine ready."*

</details>

**Вопрос 3:** Как масштабировать service?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** `--scale` flag.

```bash
# Run 3 copies of web service
docker-compose up -d --scale web=3

# Check: 3 web containers running
docker-compose ps
```

**Use cases:**
- Load balancing (3 web servers)
- Parallel processing (5 workers)
- High availability

**Limitation:** Нельзя масштабировать если есть hardcoded ports!

```yaml
# ❌ CAN'T scale:
services:
  web:
    ports:
      - "80:80"  # Port 80 only available once!

# ✅ CAN scale:
services:
  web:
    expose:
      - 80  # No host port binding
    # Use load balancer (nginx/traefik) to distribute
```

**Sophie:** *"Scaling = replication. More containers = more capacity. Compose makes it one command."*

</details>

---

## ЦИКЛ 7: Security & Best Practices — Сканирование 🔐
### (10-15 минут)

### 🎬 Сюжет: Sophie's Final Lesson

**17:30 — Before departure**

**Sophie:**
> *"Max, Dmitry. Incident сегодня — важный урок. Docker мощный. Но с силой приходит ответственность. Security best practices."*

(открывает presentation на экране)

**Sophie's Security Checklist:**

```
✅ 1. Scan images (Trivy, Snyk)
✅ 2. Use minimal base images (Alpine, Distroless)
✅ 3. Don't run as root
✅ 4. Enable Docker Content Trust
✅ 5. Regular updates
✅ 6. Private registry
✅ 7. Secrets management
```

**LILITH:**
> *"Security — это не feature. Это requirement. Как seatbelt в машине. Не опция."*

---

### 📚 Теория: Docker Security Best Practices

#### 1. Scan Images for Vulnerabilities

```bash
# Trivy (free, open source)
trivy image nginx:latest

# Docker scan (built-in)
docker scan nginx:latest

# Snyk
snyk container test nginx:latest
```

**Scan BEFORE deployment!**

```yaml
# CI/CD pipeline
script:
  - docker build -t my-app .
  - trivy image my-app || exit 1  # Fail if vulnerabilities
  - docker push my-app
```

---

#### 2. Use Minimal Base Images

```dockerfile
# ❌ BAD: 1GB, hundreds of packages, large attack surface
FROM ubuntu:latest

# ✅ GOOD: 5MB, minimal packages
FROM alpine:latest

# ✅ EVEN BETTER: < 2MB, no shell, no package manager
FROM gcr.io/distroless/static
```

**Alpine vs Ubuntu:**

| Metric | Ubuntu | Alpine |
|--------|--------|--------|
| Size | 77 MB | 5 MB |
| Packages | ~600 | ~50 |
| Attack surface | Large | Small |
| CVEs | Many | Few |

**Sophie:**
> *"Less packages = less vulnerabilities. Simple."*

---

#### 3. Don't Run as Root

```dockerfile
# ❌ BAD: runs as root (UID 0)
FROM alpine
COPY app /app
CMD ["/app"]

# ✅ GOOD: runs as non-root user
FROM alpine
RUN adduser -D appuser
USER appuser
COPY app /app
CMD ["/app"]
```

**Why it matters:**

```bash
# If attacker escapes container running as root:
# → Can access host system as root!
# → Full compromise

# If running as non-root user:
# → Limited permissions
# → Harder to escalate
```

**LILITH:**
> *"Root in container = root on host (if escape). Non-root = damage control. Always run as non-root."*

---

#### 4. Secrets Management

```dockerfile
# ❌ NEVER DO THIS:
FROM alpine
ENV DB_PASSWORD=SuperSecret123  # LEAKED IN IMAGE!
COPY app /app
CMD ["/app"]
```

```bash
# Anyone can see secrets:
docker history my-image  # Shows DB_PASSWORD! 💀
```

**✅ Correct ways:**

**A. Environment variables (runtime):**

```bash
docker run -e DB_PASSWORD=secret my-app
```

**B. Docker secrets (Swarm):**

```bash
echo "secret" | docker secret create db_password -
docker service create --secret db_password my-app
```

**C. External secrets manager:**

```bash
# Vault, AWS Secrets Manager, etc.
DB_PASSWORD=$(vault kv get -field=password secret/db)
docker run -e DB_PASSWORD=$DB_PASSWORD my-app
```

---

#### 5. Use `.dockerignore`

```dockerignore
# .dockerignore (like .gitignore for Docker)
.git
node_modules
*.log
secrets/
.env
*.key
*.pem
```

**Why:**
- ✅ Smaller images (no unnecessary files)
- ✅ Faster builds (less to copy)
- ✅ Security (no secrets in image)

---

### 💻 Практика 7: Security Scan

```bash
# 1. Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# 2. Scan popular images
trivy image nginx:latest
trivy image postgres:latest
trivy image python:3.11

# 3. Scan your custom image
cd starter/
docker build -t my-web .
trivy image my-web

# 4. Fix vulnerabilities if found
# - Update base image
# - Update dependencies
# - Rebuild

# 5. Scan again
trivy image my-web

# 6. Generate report
trivy image --format json --output report.json my-web
```

**Sophie:**
> *"Scan everything. Trust nothing. This is Docker security."*

---

### 🤔 Проверка понимания: Цикл 7

**Вопрос 1:** Почему Alpine лучше для production чем Ubuntu?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Smaller size, fewer vulnerabilities.**

- **Ubuntu:** 77 MB, ~600 packages → large attack surface
- **Alpine:** 5 MB, ~50 packages → small attack surface

**Benefits:**
- ✅ Faster downloads
- ✅ Faster starts
- ✅ Less disk space
- ✅ Fewer CVEs
- ✅ Smaller attack surface

**When NOT to use Alpine:**
- Need specific GNU tools (Alpine uses musl libc)
- Complex dependencies (some packages not available)

**Sophie:** *"95% of cases → Alpine. Special needs → Ubuntu. Default = Alpine."*

</details>

**Вопрос 2:** Что опаснее: running as root или old packages?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Running as root (IMO).**

**Root:**
- Container escape → root on host → full compromise
- Mitigated: USER non-root in Dockerfile

**Old packages:**
- Known CVEs → possible exploit
- Mitigated: regular updates, scanning

**Both dangerous!** But root = immediate system-level access.

**LILITH:** *"Old packages = unlocked window. Root access = front door key. Оба плохо, но key опаснее."*

</details>

**Вопрос 3:** Как проверить что image не содержит секретов?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Inspect layers.**

```bash
# 1. View all layers
docker history my-image

# 2. Search for secrets
docker history my-image | grep -i password
docker history my-image | grep -i secret
docker history my-image | grep -i key

# 3. Export и scan
docker save my-image > image.tar
grep -r "password" image.tar

# 4. Use automated tools
trivy config Dockerfile  # Scan Dockerfile
trivy image my-image     # Scan image
```

**Prevention:**
- Use `.dockerignore`
- Never `COPY .env` or secrets
- Use runtime env vars

**Sophie:** *"Prevention > detection. Don't put secrets in Dockerfile at all."*

</details>

**Sophie:**
> *"Dit is alles. Docker basics, images, networking, volumes, incident response, compose, security. You are ready for production."*

**Max:**
> *"Dankjewel, Sophie. Saved the operation today."*

**Sophie:**
> *"No problem. Now go automate. Hans waits in Berlin with CI/CD. Veel succes!"*

---


## 📁 Структура файлов

```
episode-14-docker-basics/
├── README.md                  # Теория + micro-cycles (этот файл)
├── artifacts/                 # Тестовые данные
│   └── README.md
│
├── starter/                   # 🎯 НАЧНИ ЗДЕСЬ!
│   ├── Dockerfile             # Docker образ с TODO комментариями
│   ├── docker-compose.yml     # Multi-service compose с TODO
│   ├── configs/               # Конфигурационные файлы
│   │   ├── nginx.conf         # Nginx с TODO
│   │   └── app.env            # Environment variables
│   ├── html/                  # Веб-файлы
│   │   └── index.html
│   ├── secrets/               # Пароли (НЕ коммитить!)
│   │   ├── db_password.txt
│   │   ├── grafana_password.txt
│   │   └── README.md
│   └── README.md              # Workflow: как работать с starter файлами
│
├── solution/                  # Референсное решение (не подглядывай!)
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── configs/
│   ├── html/
│   ├── multi-stage/           # Advanced: multi-stage builds
│   ├── secrets/
│   ├── scripts/
│   │   └── docker_helper.sh   # MINIMAL wrapper (Type B!)
│   └── README.md
│
└── tests/                     # Автотесты
    └── test.sh                # Проверка твоего решения
```

**LILITH:** *"Type B episode. Ты пишешь Dockerfile и docker-compose.yml напрямую. `starter/` содержит конфиги с TODO комментариями. Заполни их, собери образы, запусти контейнеры. docker_helper.sh — это MINIMAL wrapper, не полноценный bash скрипт. Real work делается Docker configs."*

---

## 📖 Docker Commands: Справочник

<details>
<summary><strong>🔹 Images</strong></summary>

```bash
# Pull image from registry
docker pull nginx:alpine

# Build image from Dockerfile
docker build -t my-app .
docker build -t my-app:v1.0 .  # With tag

# List images
docker images
docker images -a  # Include intermediate images

# Remove image
docker rmi nginx:alpine
docker rmi $(docker images -q)  # Remove all

# Tag image
docker tag my-app:latest my-app:v1.0

# Push to registry
docker push my-app:v1.0

# Save/load (backup)
docker save my-app > my-app.tar
docker load < my-app.tar

# Inspect
docker inspect nginx:alpine
docker history nginx:alpine  # Show layers
```

</details>

<details>
<summary><strong>🔹 Containers</strong></summary>

```bash
# Run container
docker run nginx
docker run -d nginx  # Detached (background)
docker run -d -p 8080:80 nginx  # Port mapping
docker run -d --name web nginx  # Custom name
docker run -it alpine sh  # Interactive (shell)

# List containers
docker ps  # Running
docker ps -a  # All (including stopped)

# Stop/start
docker stop web
docker start web
docker restart web

# Remove
docker rm web
docker rm -f web  # Force (stop + remove)
docker rm $(docker ps -aq)  # Remove all

# Execute command in running container
docker exec web ls /usr/share/nginx/html
docker exec -it web sh  # Interactive shell

# Logs
docker logs web
docker logs -f web  # Follow (like tail -f)

# Stats
docker stats  # Resource usage
docker top web  # Processes in container

# Copy files
docker cp file.txt web:/tmp/
docker cp web:/tmp/file.txt ./
```

</details>

<details>
<summary><strong>🔹 Networks</strong></summary>

```bash
# Create network
docker network create my-network

# List networks
docker network ls

# Connect/disconnect
docker network connect my-network web
docker network disconnect my-network web

# Inspect
docker network inspect my-network

# Remove
docker network rm my-network
docker network prune  # Remove unused networks
```

</details>

<details>
<summary><strong>🔹 Volumes</strong></summary>

```bash
# Create volume
docker volume create my-data

# List volumes
docker volume ls

# Inspect
docker volume inspect my-data

# Remove
docker volume rm my-data
docker volume prune  # Remove unused volumes
```

</details>

<details>
<summary><strong>🔹 Docker Compose</strong></summary>

```bash
# Start services
docker-compose up
docker-compose up -d  # Detached

# Stop services
docker-compose down
docker-compose down -v  # Also remove volumes

# List services
docker-compose ps

# Logs
docker-compose logs
docker-compose logs -f web  # Follow specific service

# Execute command
docker-compose exec web sh

# Build/rebuild
docker-compose build
docker-compose up --build  # Rebuild and start

# Scale
docker-compose up -d --scale web=3

# Restart
docker-compose restart web
```

</details>

<details>
<summary><strong>🔹 System</strong></summary>

```bash
# System info
docker info
docker version

# Disk usage
docker system df

# Cleanup
docker system prune  # Remove unused data
docker system prune -a  # Also remove unused images

# Events (live)
docker events
```

</details>

---

## 🧪 Тестирование

Автоматические тесты проверят:

1. ✅ Docker установлен и работает
2. ✅ Custom Dockerfile создан и собирается
3. ✅ Container запускается и отвечает
4. ✅ Networking настроен правильно
5. ✅ Volumes работают (data persists)
6. ✅ docker-compose.yml корректен
7. ✅ Multi-container stack запускается
8. ✅ Security: no secrets in images

**Запуск тестов:**

```bash
cd ~/kernel-shadows/season-4-devops-automation/episode-14-docker-basics
./tests/test.sh
```

---

## 💬 Цитаты Episode 14

**Sophie van Dijk:**
> "Containers zijn als LEGO. Simple blocks, complex systems. Build once, run anywhere."

> "In Amsterdam we have 165 canals, 1500 bridges. Docker networks — same idea. Canals = networks, bridges = connections. Pragmatic Dutch engineering."

> "Docker — это не магия. Это просто очень хорошая изоляция."

> "Security is not one-time. Security is process. Scan regularly. Update regularly. Monitor always."

**LILITH:**
> "LEGO — лучшая метафора для Docker. Маленькие, простые, взаимозаменяемые блоки. Из них строишь что угодно."

> "Container — это просто процесс. VM — это целая ОС. Процесс запускается за секунды. ОС — минуты. Вот и вся магия."

> "Supply chain атака — это отравление воды в источнике. Все кто пьют — заражены. Docker Hub — источник. Образ — вода. Check your water."

> "Compose — это дирижёр оркестра. Каждый контейнер — музыкант. Без дирижёра — хаос. С дирижёром — симфония."

> "Security — это не feature. Это requirement. Как seatbelt в машине. Не опция."

**Max Sokolov (evolution):**
- Start: "500 контейнеров на 50 серверах? Как?"
- Middle: "Данные исчезли?! Volumes!"
- After incident: "Trivy, DCT, scanning — буду использовать всё."
- End: "Containers zijn als LEGO... Теперь понятно."

---

## 🎓 Что вы узнали

После Episode 14 вы умеете:

✅ Устанавливать Docker Engine и Docker Compose
✅ Создавать Dockerfiles для custom images
✅ Понимать разницу между image и container
✅ Настраивать Docker networking (custom networks, DNS)
✅ Использовать volumes для persistent data
✅ Оптимизировать images (multi-stage builds, Alpine base)
✅ Orchestrate multi-container applications (docker-compose)
✅ Scan images для vulnerabilities (Trivy)
✅ Respond to supply chain attacks (incident response)
✅ Apply Docker security best practices

**Key concepts:**
- **Container** = lightweight, isolated process
- **Image** = template (blueprint)
- **Dockerfile** = recipe to build image
- **Network** = communication between containers
- **Volume** = persistent storage
- **Compose** = multi-container orchestration

**Эти навыки будут использоваться в:**
- Episode 15: CI/CD (автоматическая сборка Docker images)
- Episode 16: Ansible (deploy containers with Ansible)
- Season 7: Kubernetes (orchestration at scale)

---

## 🏆 Финальная проверка

**После завершения всех 7 циклов у вас должно быть:**

✅ Docker и Docker Compose установлены
✅ Custom Dockerfile создан и работает
✅ docker-compose.yml для multi-container stack
✅ Понимание networking, volumes, security
✅ Trivy scanner установлен
✅ Images отсканированы на vulnerabilities
✅ Incident response playbook понятен

**Запустите финальный тест:**

```bash
cd ~/kernel-shadows/season-4-devops-automation/episode-14-docker-basics
./tests/test.sh
```

**Expected output:**
```
✅ Docker installed
✅ Docker Compose installed
✅ Custom Dockerfile builds
✅ Container starts and responds
✅ Networking configured
✅ Volumes persist data
✅ docker-compose.yml valid
✅ Multi-container stack works
✅ No secrets in images

ALL TESTS PASSED! 🎉

Sophie would be proud. Welcome to containerization!
```

---

## 🚀 Следующий шаг

**Episode 15: CI/CD Pipelines** (Berlin, Germany)

**Hans Müller (видеозвонок из Берлина):**
> *"Max, Dmitry. Docker освоен. Теперь automation. CI/CD pipeline: автоматическая сборка images, тестирование, deployment. Возвращайтесь в Берлин. Pipeline готов. Увидимся завтра. — Hans"*

**Sophie (напутствие):**
> *"Remember: security first. Scan everything. Trust nothing. Container security = operation security. Veel succes in Berlin!"*

**LILITH:**
> *"Episode 14 complete. Docker basics → advanced. Sophie taught you well. Incident survived. Security learned. Amsterdam mission accomplished. Next: Automation."*

---

<div align="center">

**Episode 14: Docker Basics — COMPLETE!**

*"Containers zijn als LEGO. Simple blocks, complex systems."*

🇳🇱 Amsterdam • Science Park • Sophie van Dijk • Docker Architecture

[⬅️ Episode 13: Git](../episode-13-git-version-control/README.md) | [⬆️ Season 4 Overview](../README.md) | [➡️ Episode 15: CI/CD](../episode-15-cicd-pipelines/README.md)

</div>

