# Episode 13: Git & Version Control — Starter Files

## 📁 Что здесь

**Шаблоны конфигурационных файлов для настройки Git repository:**

- `.gitignore.template` — шаблон для защиты secrets
- `configs/.env.example` — template для environment variables
- `configs/BRANCHING_STRATEGY.md` — документация branching workflow
- `docs/SECRETS_MANAGEMENT.md` — руководство по безопасному хранению секретов

## 🚀 Как использовать

### 1. Initialize Git repository

```bash
# Создать папку для infrastructure
mkdir -p ~/operation-shadow-infrastructure
cd ~/operation-shadow-infrastructure

# Инициализировать Git
git init

# Настроить Git user
git config user.name "Max Sokolov"
git config user.email "max@operation-shadow.net"
```

### 2. Setup .gitignore (ПЕРВЫМ ДЕЛОМ!)

```bash
# Скопировать шаблон
cp ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control/starter/.gitignore.template .gitignore

# Commit .gitignore
git add .gitignore
git commit -m "chore: add .gitignore for secrets protection"
```

**⚠️ КРИТИЧНО:** `.gitignore` должен быть первым коммитом! Иначе риск закоммитить secrets.

### 3. Create directory structure

```bash
# Infrastructure as Code structure
mkdir -p ansible/{playbooks,roles,inventory}
mkdir -p docker/{web,api,database}
mkdir -p terraform scripts docs

# README files
echo "# Operation Shadow Infrastructure" > README.md
echo "# Ansible Playbooks" > ansible/README.md
echo "# Docker Containers" > docker/README.md
echo "# Documentation" > docs/README.md

# Commit structure
git add .
git commit -m "chore: initialize infrastructure directory structure"
```

### 4. Setup secrets management

```bash
# Copy templates
cp ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control/starter/configs/.env.example .env.example
cp ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control/starter/docs/SECRETS_MANAGEMENT.md docs/

# Create actual .env (будет ignored)
cp .env.example .env
# Edit .env with real secrets (не коммитится!)

# Commit templates (но не .env!)
git add .env.example docs/SECRETS_MANAGEMENT.md
git commit -m "chore: add secrets management templates"

# Verify .env is ignored
git status  # .env НЕ должен появиться
```

### 5. Setup branching strategy

```bash
# Copy documentation
cp ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control/starter/configs/BRANCHING_STRATEGY.md docs/

# Create branches
git checkout -b development
git checkout -b feature/episode13-git
git checkout -b feature/episode14-docker

# Back to main
git checkout main

# Commit branching docs
git add docs/BRANCHING_STRATEGY.md
git commit -m "docs: add branching strategy documentation"
```

### 6. Create sample infrastructure files

**Ansible playbook:**
```bash
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Start nginx
      systemd:
        name: nginx
        state: started
        enabled: yes
EOF

git add ansible/playbooks/webservers.yml
git commit -m "feat: add ansible playbook for nginx webservers"
```

**Dockerfile:**
```bash
mkdir -p docker/web
cat > docker/web/Dockerfile << 'EOF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

git add docker/web/Dockerfile
git commit -m "feat: add nginx Dockerfile for web containers"
```

### 7. Practice: Merge conflict simulation

(см. README.md Episode 13 — Задание 6)

### 8. Practice: Leaked secret handling

(см. README.md Episode 13 — Задание 8)

## 📋 Checklist

После завершения у вас должно быть:

- ✅ Git repository инициализирован (`git init`)
- ✅ `.gitignore` настроен (secrets защищены)
- ✅ Структура папок (ansible/, docker/, terraform/, scripts/, docs/)
- ✅ `.env.example` + `.env` (только example в Git!)
- ✅ Branching strategy документирована
- ✅ 10+ commits с правильными сообщениями (Conventional Commits)
- ✅ Secrets management руководство

## 🧪 Тестирование

```bash
cd ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control
./tests/test.sh
```

## 💡 Ключевые принципы

1. **`.gitignore` ПЕРВЫМ!** — до любых коммитов с файлами
2. **Never commit secrets** — даже на секунду
3. **Commit often** — маленькие commits лучше больших
4. **Proper messages** — Conventional Commits (feat:, fix:, docs:, chore:)
5. **Branch strategy** — main всегда стабилен, фичи в feature branches

---

**LILITH:**
> *".gitignore — это первая линия обороны. Commit messages — твоя документация. Branches — твоя песочница. Git — твоя Time Machine. Используй мудро."*

