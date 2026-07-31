# Episode 15 Artifacts: CI/CD Pipelines Testing Guide

## 📦 Содержание

Этот каталог содержит инструкции для тестирования CI/CD pipeline.

## 🧪 Тестирование CI/CD Setup

### 1. Verify GitHub Actions Workflow

**Локальное тестирование с `act`:**

```bash
# Install act (GitHub Actions local runner)
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Test workflow locally
cd ~/operation-shadow-cicd
act -l  # List workflows

# Run test job
act -j test

# Run build job (requires Docker)
act -j build-and-push --secret-file .env.secrets
```

**GitHub testing:**

```bash
# Push to GitHub
git add -A
git commit -m "test: verify CI/CD pipeline"
git push origin main

# Watch Actions
# GitHub repo → Actions tab → Watch workflow run
```

### 2. Test Automated Testing

```bash
cd ~/operation-shadow-cicd

# Run tests manually
./tests/test.sh

# Expected output:
# Running tests...
# ✓ Dockerfile exists
# ✓ Dockerfile builds successfully
# ✓ Application starts and responds
# All tests passed!
```

### 3. Test Docker Build

```bash
# Build image
docker build -t operation-shadow:test .

# Verify image
docker images | grep operation-shadow

# Test container
docker run -d -p 8080:80 --name test-app operation-shadow:test

# Health check
curl http://localhost:8080/health
# Expected: OK

curl http://localhost:8080/api/status
# Expected: {"status":"healthy","version":"1.0.0"}

# Cleanup
docker stop test-app
docker rm test-app
```

### 4. Simulate Staging Deployment

```bash
# Use Docker Compose locally
cd ~/operation-shadow-cicd
docker-compose up -d

# Verify
docker-compose ps
curl http://localhost/health

# Logs
docker-compose logs -f

# Stop
docker-compose down
```

### 5. Test Rollback Procedure

**Emergency rollback simulation:**

```bash
# Tag current version
docker tag operation-shadow:latest operation-shadow:v1.0.0

# "Deploy" broken version
echo "BROKEN" > index.html
docker build -t operation-shadow:v1.1.0-broken .
docker tag operation-shadow:v1.1.0-broken operation-shadow:latest

# Test — should fail
docker run -d -p 8080:80 --name broken-app operation-shadow:latest
curl http://localhost:8080  # Shows "BROKEN"

# ROLLBACK
docker stop broken-app
docker rm broken-app
docker tag operation-shadow:v1.0.0 operation-shadow:latest
docker run -d -p 8080:80 --name restored-app operation-shadow:latest

# Verify — should work
curl http://localhost:8080  # Shows original content

# Time this process — should be < 5 minutes
```

### 6. Blue-Green Deployment Simulation

```bash
# Blue (current production) on port 8080
docker run -d -p 8080:80 --name app-blue operation-shadow:v1.0.0

# Green (new version) on port 8081
docker run -d -p 8081:80 --name app-green operation-shadow:v1.1.0

# Test green
curl http://localhost:8081/health

# If OK, switch traffic (nginx/load balancer)
# In production: update nginx config, reload

# Stop blue
docker stop app-blue
docker rm app-blue

# Rename green → blue
docker stop app-green
docker rename app-green app-blue
docker start app-blue
```

## 🔐 Secrets Configuration

### GitHub Secrets Setup

**1. Docker Hub credentials:**

```bash
# Create Docker Hub access token
# hub.docker.com → Account Settings → Security → New Access Token

# Add to GitHub:
# Repo → Settings → Secrets → Actions → New repository secret
# Name: DOCKER_USERNAME, Value: your-username
# Name: DOCKER_PASSWORD, Value: your-access-token
```

**2. SSH keys for deployment:**

```bash
# Generate deployment key
ssh-keygen -t ed25519 -C "cicd-deploy" -f ~/.ssh/deploy_key

# Copy public key to servers
ssh-copy-id -i ~/.ssh/deploy_key.pub user@staging-server
ssh-copy-id -i ~/.ssh/deploy_key.pub user@production-server

# Add private key to GitHub secrets
cat ~/.ssh/deploy_key | pbcopy  # macOS
cat ~/.ssh/deploy_key | xclip   # Linux

# GitHub secret:
# Name: STAGING_SSH_KEY
# Value: [paste private key]
```

**3. Server configuration:**

```bash
# Add to GitHub secrets:
STAGING_HOST=staging.example.com
STAGING_USER=deploy
STAGING_URL=https://staging.example.com

PRODUCTION_HOST=production.example.com
PRODUCTION_USER=deploy
PRODUCTION_URL=https://example.com
```

### Environment Protection Rules

**Setup production environment protection:**

1. GitHub → Settings → Environments
2. Click "New environment" → Name: `production`
3. Enable "Required reviewers"
4. Add reviewers: Max, Dmitry, Hans
5. Enable "Wait timer": 5 minutes (optional)

**Result:** Production deployments будут требовать manual approval.

## 📊 Monitoring CI/CD Pipeline

### GitHub Actions Dashboard

```bash
# CLI monitoring
gh run list --limit 10
gh run view [run-id]
gh run watch  # Live updates

# Web UI
# GitHub repo → Actions → Select workflow run
```

### Deployment Metrics

**Track these metrics:**

- **Build time:** Should be < 5 minutes
- **Test time:** Should be < 2 minutes
- **Deployment time:** Should be < 3 minutes
- **Total pipeline time:** Should be < 15 minutes

**Monitor in Grafana:**

```bash
# Prometheus queries
rate(github_actions_build_duration_seconds_sum[5m])
github_actions_success_rate
github_actions_deployment_count
```

## 🚨 Incident Response Checklist

### When Production Breaks

**⏱ Time limit: 5 minutes**

**Step 1: Identify (30 seconds)**
```bash
# Check recent deployments
gh run list --limit 5

# Find last successful deployment
git log --oneline -5
```

**Step 2: Rollback (2 minutes)**
```bash
# Method 1: GitHub Actions
gh workflow run rollback.yml -f version=<PREVIOUS_SHA> -f reason="Production HTTP 500"

# Method 2: Direct SSH
ssh production "cd /opt/operation-shadow && docker tag operation-shadow:rollback operation-shadow:latest && docker-compose up -d"
```

**Step 3: Verify (1 minute)**
```bash
# Health check
curl -I https://operation-shadow.net/health
# Expected: HTTP/1.1 200 OK

# Check metrics
# Grafana → Error rate should drop to 0
```

**Step 4: Document (1.5 minutes)**
```bash
# Create incident report
cat > incident-$(date +%Y%m%d-%H%M).md << 'EOF'
# Incident Report

**Date:** $(date)
**Duration:** X minutes
**Impact:** Production HTTP 500 errors

## Root Cause
[Describe what broke]

## Resolution
Rolled back to version: [SHA]

## Prevention
- [ ] Add missing tests
- [ ] Fix configuration
- [ ] Update documentation
EOF
```

**Total time: < 5 minutes**

## 💡 Best Practices

### 1. Testing

✅ **Always test locally first**
```bash
./tests/test.sh
docker build -t test .
docker run -d -p 8080:80 test
curl http://localhost:8080
```

❌ **Never skip tests**
- Don't push directly to main without PR
- Don't deploy without staging verification

### 2. Deployments

✅ **Use staging first**
- Deploy to staging
- Run smoke tests
- Monitor for 10 minutes
- Then deploy to production

❌ **Never deploy Friday afternoon**
- Deploy Monday-Thursday morning
- Avoid holidays, weekends
- Have team available

### 3. Rollback

✅ **Always have rollback plan**
- Tag previous working version
- Test rollback procedure quarterly
- Document rollback steps
- Practice under time pressure

❌ **Never deploy without backup**
- Always tag current version before deploy
- Keep last 3-5 versions in registry

### 4. Monitoring

✅ **Monitor after deployment**
- Watch error rates (< 0.1%)
- Watch latency (p99 < 1s)
- Watch resource usage (CPU < 70%, memory < 80%)
- Monitor for at least 10 minutes

❌ **Never "fire and forget"**
- Stay online 10 minutes after deployment
- Check Grafana dashboards
- Review application logs

## 📚 Learning Objectives

После Episode 15 вы должны уметь:

- ✅ Create GitHub Actions workflows
- ✅ Automate testing in CI pipeline
- ✅ Build and push Docker images automatically
- ✅ Deploy to staging and production
- ✅ Implement manual approval gates
- ✅ Execute emergency rollback (< 5 minutes)
- ✅ Perform blue-green deployments
- ✅ Monitor post-deployment metrics
- ✅ Document incidents and post-mortems

## 🔗 Полезные ссылки

- **GitHub Actions:** https://docs.github.com/en/actions
- **act (local testing):** https://github.com/nektos/act
- **Docker:** https://docs.docker.com/
- **Blue-Green Deployment:** https://martinfowler.com/bliki/BlueGreenDeployment.html
- **CI/CD Best Practices:** https://www.atlassian.com/continuous-delivery/principles/continuous-integration-vs-delivery-vs-deployment

---

## 💬 LILITH's Notes

> *"CI/CD amplifies everything. Good code → fast success. Bad code → fast disaster. But also: fast recovery. 5 minutes rollback vs 30 minutes manual? That's automation done right."*

> *"Tests can pass but code still broken. That's why we have: staging (identical to production), monitoring (detect problems fast), rollback (recover fast). Three safety nets."*

> *"Fear of deployment is sign of bad process. Good CI/CD = deploy 10 times per day, confidently. Because you have tests, staging, monitoring, rollback. Engineering."*

---

**Hans Müller's Final Wisdom:**

> *"Remember today's incident: One commit broke 50 servers. But 5-minute rollback saved operation. Automation without safety nets = disaster. Automation WITH safety nets = superpower."*


