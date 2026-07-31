# Episode 14: Docker Basics — Solution Files

## 📁 Structure (Type B Approach!)

```
solution/
├── Dockerfile                          # Production-ready Dockerfile
├── docker-compose.yml                  # Multi-container orchestration
├── .dockerignore                       # Exclude files from build
├── configs/
│   ├── nginx.conf                      # Nginx configuration
│   └── app.env                         # Environment variables
├── html/
│   └── index.html                      # Static web content
├── multi-stage/
│   └── Dockerfile.optimized            # Multi-stage build example
├── secrets/
│   ├── db_password.txt                 # Database password (placeholder!)
│   ├── grafana_password.txt            # Grafana password (placeholder!)
│   └── README.md                       # Secrets management guide
└── scripts/
    └── docker_helper.sh                # MINIMAL wrapper (80 lines vs 657!)
```

## 🎯 Type B Philosophy

**OLD approach (657 lines bash):**
```bash
# docker_setup.sh generated everything through heredoc:
cat > Dockerfile << 'EOF'
...
EOF
cat > docker-compose.yml << 'EOF'
...
EOF
# = bash wrapper around Docker ❌
```

**NEW approach (Type B):**
```bash
# Real configs exist as separate files ✅
docker-compose up -d    # Use Docker Compose directly!
```

**Why Type B is better:**
- ✅ Configs are version-controlled separately
- ✅ Can be edited without touching bash
- ✅ Standard Docker workflow
- ✅ No bash wrapper hiding Docker
- ✅ Students learn Docker, not bash tricks

## 🚀 Quick Start

### Option 1: Use docker-compose directly (recommended!)

```bash
cd solution/

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f web

# Stop everything
docker-compose down
```

### Option 2: Use helper script (convenience)

```bash
cd solution/scripts/

# Start services
./docker_helper.sh up

# Check status
./docker_helper.sh status

# View logs
./docker_helper.sh logs

# Stop services
./docker_helper.sh down
```

## 📦 Services Included

1. **web** — Nginx web server (port 8080)
   - Access: http://localhost:8080
   - Health check: http://localhost:8080/health

2. **db** — PostgreSQL database (internal)
   - Host: shadow-db (internal DNS)
   - Uses Docker secrets for password

3. **cache** — Redis cache (internal)
   - Host: shadow-cache (internal DNS)

4. **monitoring** — Grafana (port 3000)
   - Access: http://localhost:3000
   - User: admin
   - Password: see `secrets/grafana_password.txt`

## 🔧 Key Files Explained

### Dockerfile
Production-ready with:
- ✅ Non-root user (security)
- ✅ Health checks
- ✅ Minimal Alpine base
- ✅ Proper labels

### docker-compose.yml
Multi-container setup with:
- ✅ Custom network
- ✅ Persistent volumes
- ✅ Docker secrets
- ✅ Health checks
- ✅ Restart policies

### nginx.conf
Optimized configuration with:
- ✅ Gzip compression
- ✅ Security headers
- ✅ Rate limiting
- ✅ Health endpoint

## 🔐 Security Notes

1. **Secrets:**
   - NEVER commit real passwords to git!
   - Use Docker secrets in production
   - Current secrets are placeholders only

2. **Non-root user:**
   - Container runs as `nginx` user (not root)
   - Security best practice

3. **Read-only mounts:**
   - HTML directory mounted read-only
   - Prevents container from modifying source

## 📊 Comparison: Old vs New

| Metric | Old (docker_setup.sh) | New (Type B) |
|--------|----------------------|--------------|
| Lines of bash | 657 | 80 |
| Config files | Generated in bash | Separate files |
| Docker knowledge | Hidden | Explicit |
| Maintainability | Low | High |
| Type | ❌ A (bash wrapper) | ✅ B (configs) |

## 🎓 What You Learn

With Type B approach, you learn:
- ✅ **Real Docker** (not bash wrappers)
- ✅ **Dockerfile** syntax and best practices
- ✅ **docker-compose.yml** orchestration
- ✅ **nginx.conf** web server configuration
- ✅ **Docker secrets** for sensitive data
- ✅ **Multi-stage builds** for optimization
- ✅ **Docker networking** and volumes

## 💬 Sophie's Wisdom

> *"Docker Compose exists for a reason — use it, don't wrap it."*
>
> *"Dockerfile is configuration, not bash script. Keep them separate."*
>
> *"Containers zijn als LEGO. Build once, run anywhere."*
>
> — Sophie van Dijk, Docker Architect

## 🔄 Migration from Old Approach

If you used old `docker_setup.sh`:

```bash
# Old way (657 lines of bash)
./docker_setup.sh

# New way (direct Docker usage)
docker-compose up -d
```

Benefits:
- 🚀 Faster (no bash overhead)
- 📖 Clearer (see configs directly)
- 🔧 Easier to modify (edit YAML, not bash)
- 🎓 Learn real Docker (not bash tricks)

## 📝 Testing

```bash
# Build and start
docker-compose up -d --build

# Test web service
curl http://localhost:8080
curl http://localhost:8080/health

# Test database connection
docker-compose exec db psql -U shadow_user -d operation_shadow -c "SELECT version();"

# Test Redis
docker-compose exec cache redis-cli ping

# Check logs
docker-compose logs -f

# Cleanup
docker-compose down -v
```

## ✅ Episode 14 Complete!

You now understand **Docker the RIGHT way** — with real configs, not bash wrappers!

Next: **Episode 15** (CI/CD Pipelines) — автоматизация Docker builds через GitLab CI!


