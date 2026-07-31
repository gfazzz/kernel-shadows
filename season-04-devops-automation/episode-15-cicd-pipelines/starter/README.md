# Starter Files — Episode 15: CI/CD Pipelines

> **"Пиши CI/CD конфиг напрямую, не оборачивай в bash."**  
> — Философия Type B episodes

---

## 📁 Что здесь?

Эта директория содержит **GitLab CI/CD конфигурацию с TODO комментариями**.

Твоя задача — заполнить TODO, push в GitLab, наблюдать за pipeline.

```
starter/
├── .gitlab-ci.yml          # GitLab CI/CD pipeline с TODO
├── scripts/
│   └── deploy.sh           # Deployment helper (опционально)
└── README.md               # Этот файл
```

---

## 🎯 Цель задания

**Научиться писать production-ready CI/CD pipelines:**
- ✅ GitLab CI/CD syntax (stages, jobs, variables)
- ✅ Test stage — linting, unit tests, security scan
- ✅ Build stage — Docker image build & push
- ✅ Deploy stage — staging/production deployment
- ✅ Blue-green deployment strategy
- ✅ Manual approval для production

**НЕ писать bash wrapper вокруг GitLab CI!**

---

## 🔄 Workflow студента

### Шаг 1: Заполни TODO в .gitlab-ci.yml

```bash
nano starter/.gitlab-ci.yml
```

**Заполни TODO 1-9:**
- stages — этапы pipeline
- variables — глобальные переменные
- services — Docker-in-Docker
- test:lint — shellcheck linter
- test:unit — unit tests
- test:security — Trivy security scan
- build:docker — Docker image build & push
- deploy:staging — deploy to staging
- deploy:production — deploy to production с blue-green

---

### Шаг 2: Создай GitLab repository

```bash
# Если ещё не создан
# 1. Создай репозиторий на GitLab.com или self-hosted
# 2. Клонируй локально

git clone https://gitlab.com/username/operation-shadow.git
cd operation-shadow

# Скопируй starter файлы
cp /path/to/starter/.gitlab-ci.yml .
git add .gitlab-ci.yml
git commit -m "Add CI/CD pipeline"
git push
```

---

### Шаг 3: Настрой CI/CD Variables в GitLab

GitLab → Settings → CI/CD → Variables → Add Variable:

```
CI_REGISTRY_USER       = ваш GitLab username
CI_REGISTRY_PASSWORD   = Personal Access Token (Settings → Access Tokens)
SSH_PRIVATE_KEY        = SSH ключ для deployment (см. ниже)
STAGING_SERVER         = IP staging server (опционально для локального теста)
PRODUCTION_SERVER      = IP production server (опционально)
```

**Как создать Personal Access Token:**
1. GitLab → Settings → Access Tokens
2. Name: `CI/CD Token`
3. Scopes: `read_registry`, `write_registry`
4. Create token
5. Скопируй и сохрани (показывается только раз!)

**Как создать SSH ключ для deployment:**
```bash
ssh-keygen -t ed25519 -C "gitlab-ci-deployment"
# Файл: ~/.ssh/gitlab_deployment
# Passphrase: оставь пустым

# Публичный ключ на remote server
ssh-copy-id -i ~/.ssh/gitlab_deployment.pub deploy@staging-server

# Приватный ключ в GitLab Variables
cat ~/.ssh/gitlab_deployment
# Скопируй весь output в SSH_PRIVATE_KEY variable
```

---

### Шаг 4: Push и наблюдай за pipeline

```bash
git push origin main
```

**GitLab автоматически:**
1. Обнаружит `.gitlab-ci.yml`
2. Запустит pipeline
3. Покажет progress в UI

**Мониторь pipeline:**
- GitLab → CI/CD → Pipelines
- Кликни на pipeline ID
- Увидишь stages и jobs

---

### Шаг 5: Понимание stages

**STAGE 1: test** (автоматически)
- `test:lint` — shellcheck для .sh файлов
- `test:unit` — запуск tests/run_tests.sh
- `test:security` — Trivy security scan

**Если test stage упал:**
```bash
# Смотри логи в GitLab
# Исправь код локально
git add .
git commit -m "Fix lint errors"
git push
# Pipeline перезапустится автоматически
```

**STAGE 2: build** (автоматически после test)
- `build:docker` — собирает Docker образ, push в registry

**STAGE 3: deploy** (MANUAL!)
- `deploy:staging` — deploy на staging (manual approval)
- `deploy:production` — deploy на production (manual approval)

---

### Шаг 6: Manual deployment

**Когда pipeline дойдёт до deploy stage:**
1. Увидишь "Manual job" в GitLab UI
2. Кликни "Play" (▶️) button
3. Job запустится
4. Deployment выполнится

**LILITH:** *"Manual approval — это страховка. Production деплой требует человеческого подтверждения. Automation — хорошо, но не для финального шага."*

---

## ✅ Чеклист выполнения

- [ ] Заполнил TODO в `.gitlab-ci.yml`
- [ ] Создал GitLab repository
- [ ] Push `.gitlab-ci.yml` в git
- [ ] Настроил CI/CD Variables (CI_REGISTRY_USER, CI_REGISTRY_PASSWORD)
- [ ] Pipeline запустился автоматически
- [ ] test stage прошёл успешно
- [ ] build stage прошёл успешно
- [ ] Попробовал manual deploy (staging или production)
- [ ] Изучил логи каждого job
- [ ] Понял как работает blue-green deployment

---

## 🚨 Troubleshooting

### Проблема: Pipeline не запускается

```
# Проверь что .gitlab-ci.yml в корне репозитория
ls -la .gitlab-ci.yml

# Проверь синтаксис YAML
# Онлайн: https://www.yamllint.com/
# Или локально:
yamllint .gitlab-ci.yml
```

---

### Проблема: docker login failed

```
Error: unauthorized: HTTP Basic: Access denied

# Проверь CI_REGISTRY_USER и CI_REGISTRY_PASSWORD variables
GitLab → Settings → CI/CD → Variables

# Убедись что Personal Access Token имеет права:
# - read_registry
# - write_registry
```

---

### Проблема: SSH deployment failed

```
Permission denied (publickey)

# Проверь что:
# 1. SSH_PRIVATE_KEY добавлен в GitLab Variables
# 2. Соответствующий публичный ключ на remote server
# 3. User 'deploy' существует на remote server

# На remote server:
sudo adduser deploy
echo "YOUR_PUBLIC_KEY" >> /home/deploy/.ssh/authorized_keys
```

---

## 💡 Best Practices (Hans's notes)

### ✅ DO

- ✅ Используй stages для организации
- ✅ Pin версии Docker images (docker:24, не latest)
- ✅ Храни secrets в GitLab Variables
- ✅ Manual approval для production
- ✅ Healthcheck после deployment
- ✅ Blue-green для zero-downtime
- ✅ Artifacts для test results
- ✅ allow_failure для опциональных jobs

### ❌ DON'T

- ❌ НЕ храни secrets в .gitlab-ci.yml
- ❌ НЕ деплой в production автоматически
- ❌ НЕ забывай про rollback strategy
- ❌ НЕ используй latest tag
- ❌ НЕ игнорируй failed tests

---

## 🎓 Вопросы для самопроверки

1. **Что такое stages в GitLab CI?**
   <details><summary>Ответ</summary>
   Этапы pipeline (test → build → deploy). Stages выполняются последовательно, jobs внутри stage параллельно.
   </details>

2. **Зачем when: manual?**
   <details><summary>Ответ</summary>
   Требует ручного подтверждения в UI. Критично для production deployment — не деплоить автоматически!
   </details>

3. **Что такое Blue-green deployment?**
   <details><summary>Ответ</summary>
   Zero-downtime strategy: запускаешь новую версию, проверяешь healthcheck, переключаешь traffic, удаляешь старую.
   </details>

---

**"Automate carefully. Test twice, deploy once. CI/CD is not magic — it's discipline."**

— Hans Müller, CCC Berlin

**Berlin, Germany • CI/CD Mastery!** 🇩🇪

