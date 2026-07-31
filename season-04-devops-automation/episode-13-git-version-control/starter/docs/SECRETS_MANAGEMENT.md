# Secrets Management — Operation Shadow Infrastructure

## ⚠️ GOLDEN RULE: NEVER COMMIT SECRETS TO GIT!

**Secrets include:**
- Passwords (database, SSH, sudo)
- API keys (GitHub, AWS, GitLab)
- Private keys (SSH, SSL/TLS certificates)
- Tokens (authentication, API)
- Credentials (usernames + passwords)

## 🚫 Files That MUST Be In .gitignore

```gitignore
# Secrets (NEVER commit!)
.env
.env.local
.env.production
*.pem
*.key
*_rsa
*_rsa.pub
passwords.txt
secrets.yml
credentials.json
vault_password.txt
```

## ✅ Safe Practices

### 1. Use `.env` Files (Development)

**Template approach:**

```bash
# .env.example (SAFE to commit — template only)
DB_PASSWORD=your_password_here
API_KEY=your_api_key_here

# .env (NEVER commit — real secrets)
DB_PASSWORD=SuperSecret123!
API_KEY=abc123def456

# In .gitignore:
.env
```

**Workflow:**
1. New team member clones repo
2. Copies `.env.example` to `.env`
3. Fills in real secrets
4. `.env` stays local (never committed)

### 2. Use Environment Variables (Production)

**Load secrets from environment:**

```bash
# In scripts/deploy.sh
DB_PASSWORD="${DB_PASSWORD}"  # From environment
API_KEY="${API_KEY}"
```

**Set on server:**
```bash
# In /etc/environment or systemd service
export DB_PASSWORD="production_secret"
export API_KEY="prod_key"
```

### 3. Use HashiCorp Vault (Enterprise)

**Store secrets in Vault:**

```bash
# Write secret to Vault
vault kv put secret/database password="SuperSecret123"

# Read from Vault in scripts
DB_PASSWORD=$(vault kv get -field=password secret/database)
```

**Benefits:**
- Centralized secret storage
- Access control
- Audit logs
- Automatic rotation

### 4. Use Cloud Secrets Management

**AWS Secrets Manager:**
```bash
aws secretsmanager get-secret-value \
  --secret-id operation-shadow/db-password \
  --query SecretString \
  --output text
```

**GitHub Secrets (for CI/CD):**
```yaml
# .github/workflows/deploy.yml
- name: Deploy
  env:
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

### 5. Use Ansible Vault (Ansible)

**Encrypt secrets file:**

```bash
# Create encrypted file
ansible-vault create secrets.yml
# Password: ****

# Content:
---
db_password: "SuperSecret123"
api_key: "abc123def456"

# Use in playbook:
ansible-playbook deploy.yml --ask-vault-pass
```

**In .gitignore:**
```gitignore
.vault_pass
vault_password.txt
```

## 🔥 If Secrets Are Leaked

### Immediate Actions (< 10 minutes)

**1. ROTATE SECRET IMMEDIATELY!**

```bash
# Change password in database NOW
psql -c "ALTER USER max PASSWORD 'NewSecret2024';"

# Revoke API keys
aws iam delete-access-key --access-key-id LEAKED_KEY
```

**2. Remove from Git history**

**Option A: BFG Repo-Cleaner (fast)**

```bash
# Install
sudo apt install bfg
# or download from https://rtyley.github.io/bfg-repo-cleaner/

# Remove file from all history
bfg --delete-files secrets.txt

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push --force --all
```

**Option B: git filter-branch (slow but built-in)**

```bash
# Remove file from all history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch secrets.txt" \
  --prune-empty --tag-name-filter cat -- --all

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push --force --all
```

**3. Add to .gitignore (prevent future leaks)**

```bash
echo "secrets.txt" >> .gitignore
git add .gitignore
git commit -m "fix: add secrets.txt to .gitignore after leak incident"
```

**4. Notify team**

```bash
# Email/Slack message:
"SECURITY ALERT: Password leaked in Git commit a1b2c3d.
Actions taken:
- Password rotated (old password invalid)
- Git history cleaned
- .gitignore updated
Please re-clone repository."
```

**5. Audit: Who, When, Why?**

```bash
# Find who committed
git log --all --oneline | grep "leaked"
git show <commit-hash>

# Check for other leaks
git log --all -S "password"
git log --all -S "api_key"
```

### Post-Incident

**Document incident:**

```markdown
# Incident Report: Leaked Database Password

**Date:** 2025-10-10 21:30 UTC
**Severity:** CRITICAL
**Status:** Resolved

## What Happened
Production database password committed to public GitHub repository.
Discovered 30 minutes after commit.

## Timeline
- 21:00 — Commit with secret pushed
- 21:30 — Anna discovers leak
- 21:35 — Password rotated
- 21:38 — Git history cleaned
- 21:40 — Force push completed
- 21:45 — Krylov attack blocked (old password invalid)

## Actions Taken
1. Rotated password immediately
2. Removed from Git history (BFG)
3. Force pushed to remote
4. Updated .gitignore
5. Notified team

## Root Cause
- No .gitignore for secrets.txt
- Team member unfamiliar with Git security

## Prevention
1. Pre-commit hooks (scan for secrets)
2. Team training on Git security
3. .gitignore templates in all repos
4. Automated secret scanning (GitHub Advanced Security)

## Lessons Learned
- .gitignore FIRST, commit SECOND
- Password rotation < 5 minutes critical
- Automated tools essential for large teams
```

## 🛡️ Prevention Tools

### 1. Pre-commit Hooks (git-secrets)

```bash
# Install git-secrets
git clone https://github.com/awslabs/git-secrets
cd git-secrets
sudo make install

# Setup in repo
git secrets --install
git secrets --register-aws  # AWS patterns

# Test
echo "AWS_KEY=AKIAIOSFODNN7EXAMPLE" > test.txt
git add test.txt
git commit -m "test"
# Prevented: AWS key detected!
```

### 2. GitHub Secret Scanning

**Enable on GitHub:**
- Settings → Security → Secret scanning → Enable

**Detects:**
- AWS keys
- GitHub tokens
- Google API keys
- Slack tokens
- etc.

### 3. GitGuardian

**CI/CD integration:**

```yaml
# .gitlab-ci.yml
secret-scan:
  image: gitguardian/ggshield:latest
  script:
    - ggshield scan ci
```

## 📋 Secrets Checklist

Before committing:

- [ ] `.gitignore` created FIRST
- [ ] All secret files in `.gitignore`
- [ ] Only `.env.example` committed (not `.env`)
- [ ] No hardcoded passwords in code
- [ ] No API keys in configs
- [ ] Checked with `git diff --staged`
- [ ] Pre-commit hooks enabled

## 📖 Current Secrets Locations

### Development (Local)
- Database credentials: `.env` (in .gitignore)
- SSH keys: `~/.ssh/` (NOT in repo)
- Ansible vault: `.vault_pass` (in .gitignore)

### Production (Remote)
- Database: HashiCorp Vault → `secret/production/database`
- API keys: AWS Secrets Manager
- SSL certs: `/etc/ssl/` on servers (Ansible-managed)
- SSH keys: Ansible vault (encrypted)

## 💡 Best Practices Summary

1. **`.gitignore` first, code second** — ALWAYS
2. **Template approach** — commit `.env.example`, ignore `.env`
3. **Separate by environment** — dev/staging/prod secrets NEVER mixed
4. **Rotate regularly** — passwords expire, keys rotate
5. **Principle of least privilege** — limit who has access
6. **Audit regularly** — check Git history for leaks
7. **Automate detection** — pre-commit hooks, secret scanning

---

**LILITH:**
> *"Secrets в Git — как татуировка на лбу. Можешь потом удалить, но все уже увидели. Боты сфотографировали. Ротируй пароль. Сейчас же."*

**Hans Müller (CCC):**
> *"В Германии мы говорим: Vertrauen ist gut, Kontrolle ist besser. Trust is good, control is better. `.gitignore` — это control. Use it."*

