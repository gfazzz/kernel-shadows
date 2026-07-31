# Secrets Management

## ⚠️ SECURITY WARNING

**NEVER commit real secrets to git!**

This directory contains example/placeholder secrets for Episode 14. In production:

1. ✅ Use Docker secrets (Swarm mode)
2. ✅ Use environment variables from secure storage
3. ✅ Use external secret management (HashiCorp Vault, AWS Secrets Manager)
4. ❌ DON'T hardcode passwords in files
5. ❌ DON'T commit secrets to git (add `secrets/` to .gitignore)

## Files in this directory:

- `db_password.txt` — PostgreSQL database password
- `grafana_password.txt` — Grafana admin password

## How Docker Compose uses secrets:

```yaml
services:
  db:
    secrets:
      - db_password
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

Docker mounts secrets as read-only files in `/run/secrets/` inside containers.

## Production recommendations:

### Docker Swarm:
```bash
# Create secret from stdin
echo "MySecurePassword" | docker secret create db_password -

# Use in stack
docker stack deploy -c docker-compose.yml shadow
```

### Kubernetes:
```bash
# Create secret
kubectl create secret generic db-credentials \
  --from-literal=password=MySecurePassword

# Use in pod
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
```

### Environment variables (less secure, but better than hardcoding):
```bash
# Set in shell
export DB_PASSWORD="MySecurePassword"

# Reference in docker-compose.yml
environment:
  - DB_PASSWORD=${DB_PASSWORD}
```

## For Episode 14:

These placeholder secrets are OK for learning. But remember:

> *"Real secrets = real security. Placeholder secrets = real vulnerabilities."*
> — Sophie van Dijk, Docker Architect

**When you move to production, CHANGE ALL PASSWORDS!**


