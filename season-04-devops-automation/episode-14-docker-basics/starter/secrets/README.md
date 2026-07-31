# Secrets Directory

⚠️ **SECURITY WARNING** ⚠️

Эта директория содержит **sensitive data** (пароли, API keys, certificates).

## Правила безопасности:

1. ✅ **ВСЕГДА добавляй secrets/ в .gitignore**
2. ❌ **НИКОГДА не коммить пароли в git**
3. ✅ Используй сложные пароли (минимум 16 символов)
4. ✅ В production используй secret management:
   - Docker Swarm Secrets
   - Kubernetes Secrets
   - HashiCorp Vault
   - AWS Secrets Manager
   - Azure Key Vault

## Текущие файлы:

- `db_password.txt` — пароль PostgreSQL
- `grafana_password.txt` — пароль Grafana admin

## Как использовать:

В `docker-compose.yml`:

```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt

services:
  db:
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
```

Docker смонтирует secrets в `/run/secrets/` внутри контейнера.

## ⚠️ Для production:

**НЕ используй файлы secrets в production!**

Используй external secret management:

```yaml
secrets:
  db_password:
    external: true  # Получить из external источника
```

**Sophie:** *"Secrets in git = game over. Always use secret management in production."*

