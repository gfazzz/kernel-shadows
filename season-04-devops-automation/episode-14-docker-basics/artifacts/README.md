# Episode 14: Docker Basics — Artifacts

## 📁 Artifacts для Episode 14

Episode 14 создаёт Docker infrastructure (`~/operation-shadow-docker/`) со всеми необходимыми контейнерами.

Artifacts этого эпизода — это **Docker images, containers, и compose configurations**.

---

## 🎯 Что будет создано

### 1. Docker Project Structure

После выполнения всех заданий у вас будет:

```
~/operation-shadow-docker/
├── web/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── html/
│       └── index.html
│
├── tool/
│   ├── Dockerfile (multi-stage)
│   └── crypto_tool.c
│
├── compose/
│   └── docker-compose.yml
│
├── scripts/
│   └── docker_audit.sh
│
└── EPISODE14_COMPLETION.md
```

### 2. Docker Images

- `operation-shadow/web:latest` — Nginx web server
- `shadow-tool:multi-stage` — Optimized tool (multi-stage build)
- `nginx:alpine` — Base image (pulled)
- `postgres:15-alpine` — Database (pulled)
- `redis:7-alpine` — Cache (pulled)

### 3. Docker Containers

- `shadow-web` — Main web server (port 8080)
- `shadow-web-compose` — Web from Compose (port 8081)
- `shadow-db` — PostgreSQL database
- `shadow-cache` — Redis cache
- `web1`, `web2` — Network testing containers

### 4. Docker Networks

- `bridge` — Default network
- `shadow-network` — Custom bridge network
- `shadow-net` — Compose network

### 5. Docker Volumes

- `shadow-data` — Persistent data volume
- `db-data` — PostgreSQL data (from Compose)

---

## 🧪 Testing Your Work

### 1. Check Docker Installation

```bash
# Verify Docker installed
docker --version
docker compose version

# Check Docker daemon status
sudo systemctl status docker

# Test hello-world
docker run hello-world
```

### 2. Verify Images Built

```bash
# List images
docker images

# Should see:
# operation-shadow/web:latest
# shadow-tool:multi-stage
# nginx:alpine
# postgres:15-alpine
# redis:7-alpine
```

### 3. Check Running Containers

```bash
# List running containers
docker ps

# Check specific container
docker inspect shadow-web

# View logs
docker logs shadow-web
```

### 4. Test Web Server

```bash
# Test nginx on port 8080
curl http://localhost:8080
# Should return "Operation Shadow" HTML

# Health check endpoint
curl http://localhost:8080/health
# Should return: healthy
```

### 5. Test Docker Networking

```bash
# List networks
docker network ls

# Inspect custom network
docker network inspect shadow-network

# Test container-to-container connectivity
docker exec web1 ping -c 3 web2  # If web1, web2 exist
```

### 6. Verify Volumes

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect shadow-data

# Check volume mount
docker run --rm -v shadow-data:/data alpine ls -la /data
```

### 7. Test Docker Compose

```bash
cd ~/operation-shadow-docker/compose

# Check compose status
docker compose ps

# View logs
docker compose logs

# Test database connection
docker compose exec db psql -U shadow -d shadowdb -c '\l'

# Test Redis
docker compose exec cache redis-cli ping
# Should return: PONG
```

### 8. Security Scan with Trivy

```bash
# Scan image
trivy image operation-shadow/web:latest

# Filter by severity
trivy image --severity HIGH,CRITICAL nginx:alpine

# Generate report
trivy image --format json -o trivy_report.json operation-shadow/web:latest
```

### 9. Review Audit Report

```bash
cd ~/operation-shadow-docker
./scripts/docker_audit.sh
cat docker_audit_report.txt
```

---

## 🔒 Security Notes

### Image Security

**Safe practices:**
1. Use specific image tags (not `latest` in production)
2. Scan images before deployment (`trivy image`)
3. Enable Docker Content Trust: `export DOCKER_CONTENT_TRUST=1`
4. Use minimal base images (Alpine, distroless)
5. Run as non-root user when possible

**Example secure Dockerfile:**
```dockerfile
FROM nginx:1.25-alpine  # Specific version

# Create non-root user
RUN adduser -D -u 1000 appuser

# Copy files with ownership
COPY --chown=appuser:appuser html/ /app/

# Switch to non-root
USER appuser

CMD ["nginx", "-g", "daemon off;"]
```

### Supply Chain Security

After Episode 14 incident, always:
1. **Verify image sources** — Only trusted registries
2. **Scan for vulnerabilities** — `trivy image` before deploy
3. **Check image history** — `docker history image:tag`
4. **Use signed images** — Docker Content Trust
5. **Monitor running containers** — Outbound connections, CPU/memory

### Compose Security

**Secrets management:**
```yaml
services:
  db:
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt  # Not in Git!
```

---

## 📖 Docker Commands Cheat Sheet

### Image Management
```bash
docker images                      # List images
docker build -t name:tag .         # Build image
docker pull name:tag               # Download image
docker push name:tag               # Upload image
docker rmi name:tag                # Remove image
docker tag old new                 # Tag image
docker history name:tag            # Show image layers
docker save -o file.tar name:tag   # Export image
docker load -i file.tar            # Import image
```

### Container Management
```bash
docker ps                          # Running containers
docker ps -a                       # All containers
docker run -d name                 # Run in background
docker run -it name sh             # Interactive shell
docker stop container              # Stop container
docker start container             # Start container
docker restart container           # Restart container
docker rm container                # Remove container
docker exec container cmd          # Run command
docker logs -f container           # Follow logs
docker inspect container           # Details
docker stats                       # Resource usage
```

### Networking
```bash
docker network ls                  # List networks
docker network create name         # Create network
docker network inspect name        # Inspect network
docker network connect net ctr     # Connect container
docker network disconnect net ctr  # Disconnect container
docker network rm name             # Remove network
```

### Volumes
```bash
docker volume ls                   # List volumes
docker volume create name          # Create volume
docker volume inspect name         # Inspect volume
docker volume rm name              # Remove volume
docker volume prune                # Remove unused volumes
```

### System
```bash
docker info                        # System info
docker system df                   # Disk usage
docker system prune -a             # Clean everything
docker stats                       # Live resource usage
```

### Docker Compose
```bash
docker compose up -d               # Start services
docker compose down                # Stop services
docker compose ps                  # List services
docker compose logs -f             # Follow logs
docker compose restart service     # Restart service
docker compose exec service sh     # Shell in service
docker compose build               # Rebuild images
docker compose pull                # Pull images
```

---

## 🎓 Learning Objectives

By working with these artifacts, you'll learn:

✅ Install and configure Docker
✅ Write Dockerfiles (single-stage and multi-stage)
✅ Build and run containers
✅ Docker networking (bridge, custom networks)
✅ Data persistence with volumes
✅ Multi-container orchestration (Compose)
✅ Security scanning (Trivy)
✅ Incident response (supply chain attacks)
✅ Docker best practices

---

## 🚀 Next Steps

After completing Episode 14, Docker knowledge will be used in:

- **Episode 15 (CI/CD):** Automated Docker builds with GitHub Actions
- **Episode 16 (Ansible):** Deploy containers with Ansible
- **Season 7 (Kubernetes):** Orchestration at scale

All containerized applications will be deployed throughout Season 5-8.

---

## 💡 Tips & Tricks

### Clean Up Docker System

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Clean everything (⚠️ caution!)
docker system prune -a --volumes
```

### Debug Containers

```bash
# View container logs
docker logs -f --tail 100 container

# Shell into container
docker exec -it container /bin/sh

# Inspect filesystem
docker exec container ls -la /app

# Check environment variables
docker exec container env

# Test network connectivity
docker exec container ping google.com
docker exec container wget -qO- http://example.com
```

### Optimize Images

```bash
# Use .dockerignore
cat > .dockerignore << EOF
.git
node_modules
*.log
*.tmp
EOF

# Multi-stage builds
FROM builder AS build
# ... compile ...
FROM alpine
COPY --from=build /app/binary .

# Layer optimization (combine RUN commands)
RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*
```

---

## 📚 References

- [Docker Official Docs](https://docs.docker.com/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)
- [Docker Security](https://docs.docker.com/engine/security/)

---

## 🎬 Scenario Context

**Sophie van Dijk:**
> "Docker changed the world. Before containers? Configuration hell. After containers? Build once, run anywhere. Simple. Powerful. But remember Episode 14 incident — with power comes responsibility. Always scan. Always verify."

**LILITH:**
> "Containers isolate not just code, but risk. One compromised image can't easily escape to the host. But supply chain is your weak link. Trust, but verify. Scan, then deploy. Never the opposite."

---

<div align="center">

**Episode 14 Artifacts — Docker Foundation**

*Amsterdam, Netherlands • Science Park • Container Mastery*

[⬆️ Back to Episode README](../README.md)

</div>


