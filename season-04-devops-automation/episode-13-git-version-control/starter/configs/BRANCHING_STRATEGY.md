# Branching Strategy — Operation Shadow Infrastructure

## 🌳 Branch Structure

```
main (production-ready)
 │
 ├── development (integration & testing)
 │    │
 │    ├── feature/episode13-git (Max)
 │    ├── feature/episode14-docker (Dmitry)
 │    ├── feature/episode15-cicd (Anna)
 │    └── feature/episode16-ansible (Alex)
 │
 └── hotfix/security-patch (emergency fixes)
```

## 📋 Branch Types

### 1. `main` — Production Branch
- **Purpose:** Production-ready infrastructure
- **Rules:**
  - ❌ NEVER commit directly to main
  - ✅ Only merge from development (after testing)
  - ✅ Protected branch (requires pull request + review)
  - ✅ Always stable

### 2. `development` — Integration Branch
- **Purpose:** Integration & testing before production
- **Rules:**
  - Merge feature branches here first
  - Run tests, validate configs
  - When stable → merge to main

### 3. `feature/name` — Feature Branches
- **Purpose:** Develop new features/configs
- **Naming:**
  - `feature/episode13-git`
  - `feature/ansible-webservers`
  - `feature/docker-monitoring`
- **Lifetime:** Short-lived (2-7 days max)
- **Rules:**
  - Branch from `development`
  - Small, focused changes
  - Delete after merge

### 4. `hotfix/name` — Emergency Fixes
- **Purpose:** Urgent production fixes
- **Naming:**
  - `hotfix/password-leak`
  - `hotfix/firewall-rule`
  - `hotfix/ssl-cert-expired`
- **Rules:**
  - Branch from `main`
  - Fix critical issue
  - Merge to both `main` AND `development`

## 🔄 Workflow

### Feature Development Workflow

```bash
# 1. Start from development
git checkout development
git pull origin development

# 2. Create feature branch
git checkout -b feature/ansible-webservers

# 3. Work on feature
# ... edit files ...
git add .
git commit -m "feat: add ansible playbook for nginx"

# 4. Push to remote
git push origin feature/ansible-webservers

# 5. Create Pull Request (GitHub/GitLab)
# - Request code review
# - Wait for approval
# - CI/CD tests run automatically

# 6. Merge to development
git checkout development
git merge feature/ansible-webservers

# 7. Delete feature branch
git branch -d feature/ansible-webservers
git push origin --delete feature/ansible-webservers

# 8. When development stable → merge to main
git checkout main
git merge development
git push origin main
```

### Hotfix Workflow

```bash
# 1. Branch from main (urgent!)
git checkout main
git checkout -b hotfix/password-leak

# 2. Fix issue
# ... fix ...
git commit -m "fix: rotate leaked password"

# 3. Merge to main
git checkout main
git merge hotfix/password-leak
git push origin main

# 4. ALSO merge to development (prevent regression)
git checkout development
git merge hotfix/password-leak
git push origin development

# 5. Delete hotfix branch
git branch -d hotfix/password-leak
```

## 💬 Commit Message Convention

**Use Conventional Commits:**

```
<type>: <subject>

<body (optional)>

<footer (optional)>
```

### Types

- `feat:` — new feature (Ansible playbook, Dockerfile)
- `fix:` — bug fix (incorrect config, typo)
- `docs:` — documentation only
- `chore:` — maintenance (.gitignore, structure)
- `refactor:` — code refactoring
- `test:` — add tests

### Examples

✅ **Good:**
```
feat: add ansible playbook for nginx webservers

- Configured nginx with SSL/TLS
- Added load balancing for 5 backend servers
- Enabled HTTP/2 support
```

```
fix: correct firewall rule for port 8080

Previously blocked traffic to monitoring server.
Now allows TCP connections from 10.20.30.0/24.
```

❌ **Bad:**
```
update
fix stuff
changes
```

## 🔒 Protected Branches

**Configure on GitHub/GitLab:**

### `main` branch protection:
- ✅ Require pull request reviews (minimum 1)
- ✅ Require status checks to pass (CI/CD tests)
- ✅ Require branches to be up to date
- ✅ Restrict who can push (only leads)

### `development` branch protection:
- ✅ Require pull request reviews
- ✅ Require CI/CD tests pass

## 👥 Team Workflow

### Max (Feature Developer)
```bash
git checkout development
git checkout -b feature/episode13-git
# ... work ...
git push origin feature/episode13-git
# Create Pull Request → Code Review → Merge
```

### Dmitry (DevOps Lead)
```bash
# Reviews pull requests
# Merges to development
# Deploys to staging
# When stable → merges to main
```

### Anna (Security Review)
```bash
# Reviews all changes for security
# Checks for leaked secrets
# Approves pull requests
```

## 📖 References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

---

**LILITH:**
> *"Branching — это параллельные вселенные. В одной Max ломает всё. В другой всё работает. main — та вселенная где ВСЕГДА всё работает. Всегда."*

