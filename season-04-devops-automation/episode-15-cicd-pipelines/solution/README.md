# Episode 15: CI/CD Pipelines — Solution

## 🎯 Type B Philosophy

**"Automate carefully. Test twice, deploy once."** — Hans Müller

### OLD approach (bash wrapper ❌):
```bash
# cicd_setup.sh (677 lines!)
cat > .gitlab-ci.yml << 'EOF'
...
EOF
# Generated CI/CD configs through bash heredoc
```

### NEW approach (Type B ✅):
```yaml
# Real CI/CD pipeline files
.gitlab-ci.yml              # GitLab CI
.github/workflows/*.yml     # GitHub Actions
```

## 📁 Structure

```
solution/
├── .gitlab-ci.yml                      # GitLab CI/CD pipeline
├── .github/workflows/
│   ├── test.yml                        # CI: Linting + Tests
│   ├── build.yml                       # CD: Docker build & push
│   └── deploy.yml                      # CD: Deploy to servers
├── docker/
│   └── Dockerfile.ci                   # CI environment image
└── scripts/
    └── deploy.sh                       # Deployment script (50 lines)
```

## 🚀 GitLab CI/CD

### Pipeline Structure:
```
test → build → deploy
```

**Triggers:**
- Every push → test
- Push to main → test + build + deploy (manual)

**Stages:**
1. **test** — lint (shellcheck), unit tests, security scan (Trivy)
2. **build** — build Docker image, push to registry
3. **deploy** — deploy to staging (auto) or production (manual)

### Usage:

```bash
# Push code triggers pipeline automatically
git push origin main

# View pipeline in GitLab CI/CD
# https://gitlab.com/your-project/-/pipelines

# Manual deployment (production requires approval)
# Go to GitLab → CI/CD → Pipelines → deploy:production → Play button
```

### Required Secrets (GitLab Settings → CI/CD → Variables):
```
CI_REGISTRY_USER          # Docker registry username
CI_REGISTRY_PASSWORD      # Docker registry password
SSH_PRIVATE_KEY           # SSH key for deployment
STAGING_SERVER            # staging.operation-shadow.net
PRODUCTION_SERVER         # operation-shadow.net
SLACK_WEBHOOK            # (Optional) Slack notifications
```

## 🐙 GitHub Actions

### Workflows:
1. **test.yml** — Runs on every push/PR
   - Lint code (ShellCheck)
   - Run tests
   - Security scan (Trivy)

2. **build.yml** — Runs on push to main
   - Build Docker image
   - Push to GitHub Container Registry
   - Scan image for vulnerabilities

3. **deploy.yml** — Manual deployment
   - Deploy to staging/production
   - Health check
   - Auto-rollback on failure

### Usage:

**Automatic (CI):**
```bash
git push origin main
# Triggers test.yml and build.yml automatically
```

**Manual Deployment:**
```bash
# Go to GitHub → Actions → CD - Deploy → Run workflow
# Select environment: staging / production
# Select version: latest / specific SHA
```

### Required Secrets (GitHub Settings → Secrets and variables → Actions):
```
SSH_PRIVATE_KEY           # SSH key for servers
DEPLOY_SERVER             # Server hostname
GITHUB_TOKEN              # (Auto-provided by GitHub)
```

## 📊 Hans's "Automated Pipeline" Demo

**What Hans showed in Episode 15:**

```bash
# Developer workflow
git add .
git commit -m "feat: add new feature"
git push origin main

# CI/CD automatically:
# ✓ Lints code (10s)
# ✓ Runs tests (30s)
# ✓ Builds Docker image (2min)
# ✓ Pushes to registry (1min)
# ✓ Waits for manual approval
# → Click "Deploy to Production"
# ✓ Deploys with zero downtime (30s)
# ✓ Health check
# ✓ Sends notification

# Total: 4 minutes from commit to production!
```

## 🔧 Key CI/CD Concepts

### 1. Pipeline Stages
Sequential steps:
```yaml
stages:
  - test    # Fast feedback (fail early)
  - build   # Only if tests pass
  - deploy  # Only if build succeeds
```

### 2. Jobs
Tasks within stages:
```yaml
test:lint:
  stage: test
  script:
    - shellcheck *.sh

test:unit:
  stage: test
  script:
    - ./run_tests.sh
```

### 3. Dependencies
Jobs wait for others:
```yaml
build:
  needs: [test:lint, test:unit]  # Wait for tests
```

### 4. Manual Approval
Require human decision:
```yaml
deploy:production:
  when: manual  # Requires clicking "Play" button
```

### 5. Artifacts
Pass files between jobs:
```yaml
artifacts:
  paths:
    - build_report.txt
  expire_in: 1 week
```

## 🎓 Blue-Green Deployment (Zero Downtime)

`scripts/deploy.sh` implements blue-green deployment:

```bash
# 1. Keep old container as backup
docker rename operation-shadow operation-shadow-old

# 2. Start new container
docker run -d --name operation-shadow new-image

# 3. Health check (10s)
curl -f http://localhost/health

# 4a. If success → remove old
docker rm operation-shadow-old

# 4b. If failure → automatic rollback
docker stop operation-shadow
docker rename operation-shadow-old operation-shadow
docker start operation-shadow
```

**Zero downtime guaranteed!**

## 📈 Comparison: Old vs New

| Metric | Old (bash) | New (CI/CD) |
|--------|-----------|-------------|
| Lines of bash | 677 | 50 (deploy.sh only) |
| Configuration | Heredoc in bash | Real YAML files |
| Automation | Manual trigger | Automatic on push |
| Testing | None | Linting + Tests + Security |
| Deployment | Risky | Blue-green (zero downtime) |
| Rollback | Manual | Automatic on failure |
| Type | ❌ A (wrapper) | ✅ B (real CI/CD) |

## 🧪 Testing Locally

### Test GitLab CI locally (with gitlab-runner):
```bash
# Install gitlab-runner
sudo apt install gitlab-runner

# Test pipeline locally
gitlab-runner exec docker test:lint
gitlab-runner exec docker test:unit
```

### Test GitHub Actions locally (with act):
```bash
# Install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow locally
act push  # Simulates push event
act pull_request  # Simulates PR
```

## 💬 Hans's CI/CD Philosophy

> *"Automate carefully. Test twice, deploy once."*
>
> *"Fast feedback loops. Tests fail in 10 seconds, not 10 minutes."*
>
> *"Manual approval for production. Humans make final decision."*
>
> *"Zero downtime deployment. Blue-green strategy, automatic rollback."*
>
> *"CI/CD = YAML configs. Not bash wrappers."*

## ✅ Benefits of Type B Approach

1. **Real CI/CD** — Students learn GitLab CI/GitHub Actions, not bash
2. **Version Control** — YAML files tracked, reviewed in PRs
3. **Visual UI** — See pipeline progress in GitLab/GitHub UI
4. **Built-in features** — Artifacts, caching, matrix builds
5. **Standard** — Industry-standard CI/CD approach
6. **Secure** — Secrets management, no hardcoded passwords

## 🔄 Migration from Old Approach

If you used old `cicd_setup.sh`:

```bash
# Old way (677 lines bash generating configs)
./cicd_setup.sh

# New way (commit real YAML files to repo)
git add .gitlab-ci.yml .github/workflows/
git commit -m "ci: add CI/CD pipelines"
git push
# Pipeline runs automatically!
```

## 🎯 Episode 15 Learning Outcomes

After completing Episode 15, you understand:
- ✅ **GitLab CI/CD** (stages, jobs, artifacts)
- ✅ **GitHub Actions** (workflows, events, matrix)
- ✅ **Pipeline design** (test → build → deploy)
- ✅ **Blue-green deployment** (zero downtime)
- ✅ **Security scanning** (Trivy for vulnerabilities)
- ✅ **Secrets management** (CI/CD variables)
- ✅ **Type B philosophy** (real YAML, not bash wrappers)

## 🚀 Next Steps

**Episode 15 Complete! → Episode 16: Ansible & IaC**

Learn Infrastructure as Code with Ansible playbooks!

---

*"Automate carefully. Test twice, deploy once."* — Hans Müller, CCC

**Berlin, Germany • CCC Datacenter • CI/CD Automation**
**Day 29-30 of 60**


