#!/bin/bash

################################################################################
# KERNEL SHADOWS: Episode 13 — Git & Version Control
# SOLUTION SCRIPT (Reference Implementation)
#
# Berlin, Germany (Day 25-26)
# Hans Müller, Chaos Computer Club
#
# Mission: Complete Git setup for infrastructure as code
################################################################################

# Strict mode
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REPO_NAME="operation-shadow-infrastructure"
REPO_PATH="$HOME/$REPO_NAME"
LOG_FILE="$HOME/episode13_git_setup.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

################################################################################
# Task 1: Initialize Git repository
################################################################################
task1_init_git() {
    echo -e "${BLUE}[Task 1]${NC} Initializing Git repository..."
    log "Task 1: Initializing Git repository"

    # Remove existing repo if present (for clean run)
    if [ -d "$REPO_PATH" ]; then
        echo -e "${YELLOW}⚠${NC}  Existing repository found. Removing..."
        rm -rf "$REPO_PATH"
    fi

    # Create and navigate to directory
    mkdir -p "$REPO_PATH"
    cd "$REPO_PATH" || exit 1

    # Initialize Git
    git init

    # Configure Git user
    git config user.name "Max Sokolov"
    git config user.email "max@operation-shadow.net"

    # Verify
    log "Git initialized at $REPO_PATH"
    git config user.name
    git config user.email

    echo -e "${GREEN}✓${NC} Git repository initialized"
}

################################################################################
# Task 2: Create directory structure
################################################################################
task2_create_structure() {
    echo -e "${BLUE}[Task 2]${NC} Creating directory structure..."
    log "Task 2: Creating directory structure"

    cd "$REPO_PATH" || exit 1

    # Create directory structure
    mkdir -p ansible/{playbooks,roles,inventory}
    mkdir -p docker/{web,api,database}
    mkdir -p terraform
    mkdir -p scripts
    mkdir -p docs

    # Create README files
    cat > README.md << 'EOF'
# Operation Shadow Infrastructure

Infrastructure as Code repository for Operation Shadow.

## Structure

- `ansible/` — Ansible playbooks and roles
- `docker/` — Docker containers and Compose files
- `terraform/` — Infrastructure provisioning
- `scripts/` — Utility scripts
- `docs/` — Documentation

## Quick Start

See [GETTING_STARTED.md](docs/GETTING_STARTED.md) for setup instructions.

## Security

⚠️ **NEVER commit secrets!** See [SECRETS_MANAGEMENT.md](docs/SECRETS_MANAGEMENT.md)

## License

GPL v3 — Operation Shadow, 2025
EOF

    echo "# Ansible Playbooks" > ansible/README.md
    echo "# Docker Containers" > docker/README.md
    echo "# Documentation" > docs/README.md

    # First commit
    git add .
    git commit -m "chore: initialize infrastructure directory structure

- Created ansible/, docker/, terraform/, scripts/, docs/
- Added README files for documentation
- Organized structure for infrastructure as code"

    log "Directory structure created and committed"
    echo -e "${GREEN}✓${NC} Directory structure created"
}

################################################################################
# Task 3: Create .gitignore
################################################################################
task3_create_gitignore() {
    echo -e "${BLUE}[Task 3]${NC} Creating .gitignore..."
    log "Task 3: Creating .gitignore"

    cd "$REPO_PATH" || exit 1

    cat > .gitignore << 'EOF'
# Secrets (NEVER commit!)
.env
.env.local
.env.production
.env.*.local
*.pem
*.key
*_rsa
*_rsa.pub
*_dsa
*_dsa.pub
*_ecdsa
*_ecdsa.pub
*_ed25519
*_ed25519.pub
passwords.txt
secrets.yml
credentials.json
vault_password.txt
*.secret

# Ansible
*.retry
.vault_pass
.vault_password
ansible.cfg.local

# Terraform
*.tfstate
*.tfstate.backup
*.tfstate.lock.info
.terraform/
.terraform.lock.hcl
terraform.tfvars
terraform.tfvars.json
override.tf
override.tf.json

# Docker
docker-compose.override.yml

# Logs
*.log
logs/
*.log.*
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
desktop.ini

# Temporary files
*.tmp
*.temp
*.swp
*.swo
*~
.#*
\#*#
.*.sw[a-p]
.cache/
tmp/

# Backup files
*.bak
*.backup
*.old
*.orig
*.save

# IDE & Editors
.vscode/
.idea/
*.sublime-project
*.sublime-workspace
.project
.classpath
.settings/

# Node (if used)
node_modules/
npm-debug.log
yarn.lock
package-lock.json

# Python (if used)
__pycache__/
*.py[cod]
*$py.class
.Python
venv/
env/
.venv/
EOF

    git add .gitignore
    git commit -m "chore: add comprehensive .gitignore for secrets and temp files

Prevents committing:
- Secrets (.env, keys, passwords)
- Ansible vault passwords
- Terraform state files
- Logs and temporary files
- OS and IDE artifacts"

    log ".gitignore created with secrets protection"
    echo -e "${GREEN}✓${NC} .gitignore created"
}

################################################################################
# Task 4: Branching strategy
################################################################################
task4_branching_strategy() {
    echo -e "${BLUE}[Task 4]${NC} Setting up branching strategy..."
    log "Task 4: Branching strategy setup"

    cd "$REPO_PATH" || exit 1

    # Create development branch
    git checkout -b development
    git checkout main

    # Create feature branches (without switching)
    git branch feature/episode13-git
    git branch feature/episode14-docker
    git branch feature/episode15-cicd
    git branch feature/episode16-ansible

    # Create branching documentation
    cat > docs/BRANCHING_STRATEGY.md << 'EOF'
# Branching Strategy for Operation Shadow

## Overview

We use a **Feature Branch Workflow** with long-lived `main` and `development` branches.

## Branch Types

### Long-lived branches

- **main** — Production-ready infrastructure
  - Always deployable
  - Protected (no direct pushes)
  - Merge only from `development` via Pull Request

- **development** — Integration branch
  - For testing before production
  - Feature branches merge here first
  - CI/CD runs automated tests

### Short-lived branches

- **feature/episodeXX-name** — Feature development
  - Branched from: `development`
  - Merged to: `development`
  - Naming: `feature/episode13-git`, `feature/ansible-webservers`
  - Lifetime: < 1 week

- **hotfix/description** — Urgent production fixes
  - Branched from: `main`
  - Merged to: `main` AND `development`
  - Naming: `hotfix/password-leak`, `hotfix/nginx-config`
  - Lifetime: < 1 day

## Workflow

### Feature development

```bash
# 1. Create feature branch from development
git checkout development
git pull origin development
git checkout -b feature/new-feature

# 2. Make changes and commit
git add .
git commit -m "feat: add new feature"

# 3. Push to remote
git push origin feature/new-feature

# 4. Create Pull Request: feature/new-feature → development

# 5. After review and CI/CD pass, merge
git checkout development
git merge feature/new-feature

# 6. Delete feature branch
git branch -d feature/new-feature
git push origin --delete feature/new-feature
```

### Hotfix workflow

```bash
# 1. Create hotfix branch from main
git checkout main
git checkout -b hotfix/critical-bug

# 2. Fix and commit
git add .
git commit -m "fix: critical bug in production"

# 3. Merge to main
git checkout main
git merge hotfix/critical-bug

# 4. Merge to development (to keep in sync)
git checkout development
git merge hotfix/critical-bug

# 5. Delete hotfix branch
git branch -d hotfix/critical-bug
```

### Release to production

```bash
# When development is stable and tested:
git checkout main
git merge development
git tag -a v1.0.0 -m "Release v1.0.0: Initial infrastructure"
git push origin main --tags
```

## Commit Message Convention

We use **Conventional Commits** for semantic versioning and automated changelog generation.

### Format

```
<type>: <subject>

<body (optional)>

<footer (optional)>
```

### Types

- `feat:` — New feature (minor version bump)
- `fix:` — Bug fix (patch version bump)
- `docs:` — Documentation only changes
- `style:` — Code formatting (no code change)
- `refactor:` — Code refactoring
- `perf:` — Performance improvement
- `test:` — Adding tests
- `chore:` — Maintenance (dependencies, build tools)
- `ci:` — CI/CD configuration changes
- `build:` — Build system changes
- `revert:` — Revert previous commit

### Examples

**Good:**
```
feat: add ansible playbook for nginx webservers

- Configured nginx with SSL/TLS certificates
- Added load balancing for 5 backend servers
- Enabled HTTP/2 support
- Configured logging to /var/log/nginx/

Related: Episode 13 (Git basics)
```

```
fix: correct firewall rule for port 8080

UFW rule was blocking legitimate traffic.
Changed from DROP to ALLOW for port 8080.
```

```
docs: update README with deployment instructions

Added step-by-step guide for new team members.
```

**Bad:**
```
fix
update config
stuff
wip
```

## Branch Protection Rules

For production use (GitHub/GitLab):

### main branch
- ✅ Require pull request reviews (min 1)
- ✅ Require CI/CD status checks
- ✅ No direct pushes
- ✅ No force pushes
- ✅ Require signed commits (GPG)

### development branch
- ✅ Require CI/CD status checks
- ⚠️ Direct pushes allowed (for quick fixes)
- ❌ No force pushes

## Team Workflow

- **Max:** Feature branches for infrastructure tasks
- **Dmitry:** Feature branches for DevOps automation
- **Alex:** Security code reviews (all PRs)
- **Anna:** Forensics analysis (incident branches)

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Feature Branch Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow)
- [Semantic Versioning](https://semver.org/)
EOF

    git add docs/BRANCHING_STRATEGY.md
    git commit -m "docs: add comprehensive branching strategy

- Feature branch workflow
- Hotfix procedures
- Conventional commits guide
- Branch protection rules
- Team workflow"

    log "Branching strategy documented"
    echo -e "${GREEN}✓${NC} Branching strategy configured"
}

################################################################################
# Task 5: Sample files with proper commits
################################################################################
task5_proper_commits() {
    echo -e "${BLUE}[Task 5]${NC} Creating sample files with proper commits..."
    log "Task 5: Sample infrastructure files"

    cd "$REPO_PATH" || exit 1

    # Ansible playbook
    cat > ansible/playbooks/webservers.yml << 'EOF'
---
- name: Configure web servers for Operation Shadow
  hosts: webservers
  become: yes

  vars:
    nginx_port: 80
    nginx_worker_processes: auto

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Start and enable nginx
      systemd:
        name: nginx
        state: started
        enabled: yes

    - name: Configure firewall
      ufw:
        rule: allow
        port: "{{ nginx_port }}"
        proto: tcp
EOF

    git add ansible/playbooks/webservers.yml
    git commit -m "feat: add ansible playbook for nginx webservers

- Install and configure nginx
- Configured UFW firewall rules
- Enabled systemd service
- Ready for Episode 14 Docker integration"

    # Dockerfile
    mkdir -p docker/web
    cat > docker/web/Dockerfile << 'EOF'
FROM nginx:alpine

LABEL maintainer="max@operation-shadow.net"
LABEL version="1.0"
LABEL description="Nginx web server for Operation Shadow"

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static content
COPY html/ /usr/share/nginx/html/

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

    cat > docker/web/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    gzip on;

    server {
        listen 80;
        server_name localhost;

        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOF

    git add docker/web/
    git commit -m "feat: add nginx Dockerfile and configuration

- Alpine-based image for minimal size
- Custom nginx.conf with optimizations
- Health check endpoint
- Prepared for Episode 14 (Docker)"

    # Create sample script
    cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script for Operation Shadow infrastructure

set -euo pipefail

echo "Deploying infrastructure..."
# TODO: Add deployment logic
EOF

    chmod +x scripts/deploy.sh
    git add scripts/deploy.sh
    git commit -m "chore: add deployment script template"

    log "Sample files created with proper commit messages"
    echo -e "${GREEN}✓${NC} Sample files with proper commits"
}

################################################################################
# Task 6: Secrets management
################################################################################
task6_secrets_management() {
    echo -e "${BLUE}[Task 6]${NC} Setting up secrets management..."
    log "Task 6: Secrets management"

    cd "$REPO_PATH" || exit 1

    # Create .env.example (template)
    cat > .env.example << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=operation_shadow
DB_USER=your_username_here
DB_PASSWORD=your_password_here

# API Keys
GITHUB_TOKEN=your_github_token_here
AWS_ACCESS_KEY=your_aws_key_here
AWS_SECRET_KEY=your_aws_secret_here

# Ansible Vault Password
ANSIBLE_VAULT_PASSWORD=your_vault_password_here

# Monitoring
GRAFANA_ADMIN_PASSWORD=your_grafana_password_here
PROMETHEUS_PASSWORD=your_prometheus_password_here
EOF

    # Create actual .env (will be ignored)
    cat > .env << 'EOF'
DB_HOST=10.20.30.40
DB_PORT=5432
DB_NAME=operation_shadow
DB_USER=max_sokolov
DB_PASSWORD=SuperSecret123!

GITHUB_TOKEN=ghp_abc123def456
AWS_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

ANSIBLE_VAULT_PASSWORD=VaultPass2024!
GRAFANA_ADMIN_PASSWORD=GrafanaAdmin2024
PROMETHEUS_PASSWORD=PrometheusPass2024
EOF

    # Verify .env is ignored
    if git status | grep -q ".env"; then
        echo -e "${RED}❌${NC} ERROR: .env is NOT ignored!"
        exit 1
    fi

    git add .env.example
    git commit -m "chore: add .env.example template for secrets

Template for environment variables.
Actual .env file is in .gitignore.
Copy .env.example to .env and fill in real values."

    # Secrets management documentation
    cat > docs/SECRETS_MANAGEMENT.md << 'EOF'
# Secrets Management for Operation Shadow

## ⚠️ Critical Rule: NEVER Commit Secrets!

### What are secrets?

- Passwords
- API keys / tokens
- Private keys (.pem, .key, SSH keys)
- Database credentials
- TLS/SSL certificates
- Vault passwords
- Encryption keys

## File Protection

### Files that MUST be in .gitignore:

```gitignore
.env
.env.local
.env.production
*.pem
*.key
*_rsa
passwords.txt
secrets.yml
credentials.json
vault_password.txt
```

### Safe to commit:

- `.env.example` — template with placeholder values
- `README.md` — documentation about how to set up secrets
- Public keys (`.pub` files) — if needed

## Best Practices

### 1. Use .env files (Development)

**Safe approach:**
```bash
# Commit template
git add .env.example

# Create local .env (NOT committed)
cp .env.example .env
# Edit .env with real secrets
```

### 2. Use HashiCorp Vault (Production)

```bash
# Store secret
vault kv put secret/database password="SuperSecret123"

# Retrieve in script
DB_PASSWORD=$(vault kv get -field=password secret/database)
```

### 3. Use CI/CD Secrets (GitHub/GitLab)

**GitHub Actions:**
```yaml
- name: Deploy
  env:
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
  run: ./deploy.sh
```

**GitLab CI:**
```yaml
deploy:
  script:
    - echo $DB_PASSWORD
  variables:
    DB_PASSWORD: $CI_DB_PASSWORD  # from GitLab CI/CD settings
```

### 4. Use Ansible Vault (Ansible)

```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Use in playbook
ansible-playbook playbook.yml --ask-vault-pass
```

## If Secrets Are Leaked

### ⚠️ EMERGENCY PROCEDURE ⚠️

If you accidentally committed secrets, act immediately:

#### Step 1: Rotate the secret (IMMEDIATELY!)

Change the password/key in the actual system FIRST.

#### Step 2: Remove from Git history

**Option A: BFG Repo-Cleaner (recommended, faster)**

```bash
# Install BFG
sudo apt install bfg

# Remove file from all history
bfg --delete-files secrets.txt

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Option B: git filter-branch (slower, built-in)**

```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch secrets.txt" \
  --prune-empty --tag-name-filter cat -- --all

git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

#### Step 3: Force push (if already pushed to remote)

```bash
# ⚠️ WARNING: Rewrites history! Notify team first!
git push --force --all
git push --force --tags
```

#### Step 4: Notify team

Inform all team members that:
- History has been rewritten
- They need to re-clone the repository
- Old clones are now invalid

#### Step 5: Audit

```bash
# Check who committed the secret
git log --all --oneline | grep "leaked commit"
git show <commit-hash>

# Log the incident
echo "[$(date)] Secret leaked and removed. Password rotated." >> security_incidents.log
```

## Current Secrets Locations

### Local Development
- Database credentials: `.env` (NOT in Git)
- SSH keys: `~/.ssh/` (NOT in Git)
- Ansible vault: `ansible/.vault_pass` (NOT in Git)

### Production
- Stored in: HashiCorp Vault (vault.operation-shadow.net)
- Access: Only via secure API with tokens
- Backup: Encrypted offline storage

### CI/CD
- GitHub Actions: Repository Secrets (encrypted)
- GitLab CI: CI/CD Variables (masked)

## Verification

### Check if file is ignored:

```bash
git check-ignore -v .env
# Should output: .gitignore:1:.env    .env
```

### Search for potential leaks:

```bash
# Search commit history for "password"
git log --all -S "password" --oneline

# Search all files in history
git grep "password" $(git rev-list --all)
```

### Automated scanning:

```bash
# Install git-secrets
git secrets --install
git secrets --register-aws

# Scan repository
git secrets --scan-history
```

## References

- [git-secrets](https://github.com/awslabs/git-secrets) — Prevents committing secrets
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) — Remove large/sensitive files
- [HashiCorp Vault](https://www.vaultproject.io/) — Secret management
- [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) — Encrypt Ansible secrets

---

**Remember:** If unsure, ask. If leaked, act fast. Security > convenience.
EOF

    git add docs/SECRETS_MANAGEMENT.md
    git commit -m "docs: add comprehensive secrets management guide

- Best practices for development and production
- Emergency procedures for leaked secrets
- CI/CD integration guides
- Automated scanning tools
- Current secrets locations documented"

    log "Secrets management configured and documented"
    echo -e "${GREEN}✓${NC} Secrets management setup complete"
}

################################################################################
# Task 7: Git audit report
################################################################################
task7_audit_report() {
    echo -e "${BLUE}[Task 7]${NC} Creating Git audit report generator..."
    log "Task 7: Git audit report"

    cd "$REPO_PATH" || exit 1

    cat > scripts/git_audit.sh << 'EOF'
#!/bin/bash

################################################################################
# Git Audit Report Generator
# For Operation Shadow Infrastructure Repository
################################################################################

set -euo pipefail

REPORT="git_audit_report.txt"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

cd "$REPO_ROOT" || exit 1

# Header
cat > "$REPORT" << 'HEADER'
========================================
   GIT AUDIT REPORT
   Operation Shadow Infrastructure
========================================
HEADER

echo "   Generated: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT"
echo "" >> "$REPORT"

# Repository Information
echo "## REPOSITORY INFORMATION" >> "$REPORT"
echo "Repository: $(basename "$REPO_ROOT")" >> "$REPORT"
echo "Path: $REPO_ROOT" >> "$REPORT"
echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'N/A')" >> "$REPORT"
echo "Total commits: $(git rev-list --count HEAD 2>/dev/null || echo '0')" >> "$REPORT"
echo "Total branches: $(git branch -a 2>/dev/null | wc -l || echo '0')" >> "$REPORT"
echo "Total tags: $(git tag 2>/dev/null | wc -l || echo '0')" >> "$REPORT"
echo "" >> "$REPORT"

# Recent Commits
echo "## RECENT COMMITS (last 10)" >> "$REPORT"
if git log --oneline -10 >> "$REPORT" 2>/dev/null; then
    :
else
    echo "No commits yet" >> "$REPORT"
fi
echo "" >> "$REPORT"

# All Branches
echo "## BRANCHES" >> "$REPORT"
git branch -a >> "$REPORT" 2>/dev/null || echo "No branches" >> "$REPORT"
echo "" >> "$REPORT"

# Contributors
echo "## CONTRIBUTORS" >> "$REPORT"
if git log --format='%an <%ae>' 2>/dev/null | sort | uniq -c | sort -rn >> "$REPORT"; then
    :
else
    echo "No contributors yet" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Most Modified Files
echo "## MOST MODIFIED FILES (Top 10)" >> "$REPORT"
if git log --pretty=format: --name-only 2>/dev/null | grep -v '^$' | sort | uniq -c | sort -rg | head -10 >> "$REPORT"; then
    :
else
    echo "No file modifications tracked" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Commit Activity by Date
echo "## COMMIT ACTIVITY (Last 7 days)" >> "$REPORT"
git log --since="7 days ago" --pretty=format:"%ad" --date=short 2>/dev/null | sort | uniq -c >> "$REPORT" || echo "No recent commits" >> "$REPORT"
echo "" >> "$REPORT"

# File Type Statistics
echo "## FILE TYPE STATISTICS" >> "$REPORT"
find . -type f ! -path './.git/*' -name '*.*' 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10 >> "$REPORT" || echo "No files" >> "$REPORT"
echo "" >> "$REPORT"

# Security Audit
echo "## SECURITY AUDIT" >> "$REPORT"
echo "Checking for potential security issues..." >> "$REPORT"
echo "" >> "$REPORT"

# Check .gitignore
if [ -f .gitignore ]; then
    echo "✅ .gitignore exists ($(wc -l < .gitignore) lines)" >> "$REPORT"
else
    echo "❌ ERROR: .gitignore NOT FOUND!" >> "$REPORT"
fi

# Check for secrets in commit messages
if git log --all --oneline 2>/dev/null | grep -iE "(password|secret|key|token)" | head -5 | grep -q .; then
    echo "⚠️ WARNING: Potential secrets mentioned in commit messages:" >> "$REPORT"
    git log --all --oneline 2>/dev/null | grep -iE "(password|secret|key|token)" | head -5 >> "$REPORT"
else
    echo "✅ No obvious secret references in commit messages" >> "$REPORT"
fi

# Check for large files
echo "" >> "$REPORT"
echo "Large files (>1MB):" >> "$REPORT"
if find . -type f ! -path './.git/*' -size +1M 2>/dev/null | head -10 >> "$REPORT"; then
    :
else
    echo "✅ No large files found" >> "$REPORT"
fi

# Check for common sensitive files
echo "" >> "$REPORT"
echo "Checking for sensitive files in working directory:" >> "$REPORT"
SENSITIVE_PATTERNS=(".env" "*.pem" "*.key" "*_rsa" "passwords.txt" "secrets.yml")
FOUND_SENSITIVE=false
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if find . -type f ! -path './.git/*' -name "$pattern" 2>/dev/null | grep -q .; then
        echo "⚠️ Found: $pattern" >> "$REPORT"
        FOUND_SENSITIVE=true
    fi
done
if [ "$FOUND_SENSITIVE" = false ]; then
    echo "✅ No sensitive files in working directory" >> "$REPORT"
fi

# Repository Size
echo "" >> "$REPORT"
echo "## REPOSITORY SIZE" >> "$REPORT"
if [ -d .git ]; then
    echo "Git database (.git): $(du -sh .git 2>/dev/null | cut -f1 || echo 'N/A')" >> "$REPORT"
fi
echo "Working directory: $(du -sh --exclude=.git . 2>/dev/null | cut -f1 || echo 'N/A')" >> "$REPORT"
echo "" >> "$REPORT"

# Git Configuration
echo "## GIT CONFIGURATION" >> "$REPORT"
echo "User name: $(git config user.name 2>/dev/null || echo 'Not configured')" >> "$REPORT"
echo "User email: $(git config user.email 2>/dev/null || echo 'Not configured')" >> "$REPORT"
echo "Default branch: $(git config init.defaultBranch 2>/dev/null || echo 'main (default)')" >> "$REPORT"
echo "" >> "$REPORT"

# Remotes
echo "## REMOTE REPOSITORIES" >> "$REPORT"
if git remote -v >> "$REPORT" 2>/dev/null; then
    :
else
    echo "No remote repositories configured" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Footer
cat >> "$REPORT" << 'FOOTER'
========================================
   END OF AUDIT REPORT
========================================

Generated by: scripts/git_audit.sh
Operation Shadow Infrastructure
FOOTER

echo "✅ Git audit report generated: $REPORT"
echo ""
cat "$REPORT"
EOF

    chmod +x scripts/git_audit.sh

    # Run audit
    ./scripts/git_audit.sh

    # Commit audit script and report
    git add scripts/git_audit.sh git_audit_report.txt
    git commit -m "feat: add comprehensive git audit report generator

- Repository statistics
- Commit activity analysis
- Security audit (secrets detection)
- File type statistics
- Large file detection
- Configuration check"

    log "Git audit report generated"
    echo -e "${GREEN}✓${NC} Git audit report complete"
}

################################################################################
# Generate final summary
################################################################################
generate_summary() {
    echo -e "${CYAN}[Summary]${NC} Generating final summary..."
    log "Generating final summary"

    cd "$REPO_PATH" || exit 1

    cat > EPISODE13_COMPLETION.md << 'EOF'
# Episode 13: Git & Version Control — COMPLETION REPORT

## Tasks Completed

✅ **Task 1:** Git repository initialized
✅ **Task 2:** Directory structure created
✅ **Task 3:** .gitignore configured (secrets protected)
✅ **Task 4:** Branching strategy documented
✅ **Task 5:** Sample files with proper commits
✅ **Task 6:** Secrets management setup
✅ **Task 7:** Git audit report generated

## Repository Statistics

- **Total commits:** (see git_audit_report.txt)
- **Branches:** main, development, 4 feature branches
- **Files protected:** .env, *.pem, *.key, passwords.txt, etc.
- **Documentation:** BRANCHING_STRATEGY.md, SECRETS_MANAGEMENT.md

## Infrastructure Files Created

### Ansible
- `ansible/playbooks/webservers.yml` — Nginx configuration

### Docker
- `docker/web/Dockerfile` — Nginx container
- `docker/web/nginx.conf` — Custom nginx config

### Scripts
- `scripts/deploy.sh` — Deployment template
- `scripts/git_audit.sh` — Audit report generator

### Documentation
- `docs/BRANCHING_STRATEGY.md` — Git workflow
- `docs/SECRETS_MANAGEMENT.md` — Security best practices

## Security Measures

✅ .gitignore prevents secret commits
✅ .env.example template provided
✅ Actual .env file ignored
✅ Secrets management guide documented
✅ Audit script checks for leaked secrets

## Next Steps

Episode 14: Docker Basics (Amsterdam, Netherlands)
- Containerize infrastructure components
- Docker Compose for multi-container setups
- Learn from Sophie van Dijk

## Hans Müller's Final Words

> "Code is law. Version control is constitution. You've built the foundation.
> Now Sophie will teach you containers. Remember: Everything in Git.
> Everything versioned. Everything auditable. That's the CCC way."

---

**Operation Shadow Infrastructure — Git Foundation Complete**

*Generated: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

    git add EPISODE13_COMPLETION.md
    git commit -m "docs: add Episode 13 completion report

All tasks completed:
- Git repository with branching strategy
- Infrastructure as Code foundation
- Secrets management
- Security audit capabilities

Ready for Episode 14 (Docker)"

    log "Final summary generated"
}

################################################################################
# Main execution
################################################################################
main() {
    echo ""
    echo "================================================================"
    echo "  KERNEL SHADOWS: Episode 13 — Git & Version Control"
    echo "  SOLUTION SCRIPT (Reference Implementation)"
    echo "================================================================"
    echo "  Location: Berlin, Germany"
    echo "  Expert: Hans Müller (Chaos Computer Club)"
    echo "  Mission: Infrastructure as Code with Git"
    echo "================================================================"
    echo ""

    log "Starting Episode 13 solution script"

    # Execute tasks
    task1_init_git
    task2_create_structure
    task3_create_gitignore
    task4_branching_strategy
    task5_proper_commits
    task6_secrets_management
    task7_audit_report
    generate_summary

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Episode 13 Solution Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Repository location: $REPO_PATH"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Repository contents:"
    cd "$REPO_PATH" && tree -L 2 -a 2>/dev/null || ls -laR
    echo ""
    echo "Git statistics:"
    cd "$REPO_PATH" && git log --oneline --graph --all
    echo ""
    echo "Next episode: Episode 14 (Docker Basics) — Amsterdam"
    echo ""

    log "Episode 13 solution completed successfully"
}

# Run main function
main "$@"


