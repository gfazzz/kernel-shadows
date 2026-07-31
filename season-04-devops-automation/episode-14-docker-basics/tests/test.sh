#!/bin/bash

################################################################################
# KERNEL SHADOWS: Episode 14 — Docker Basics
# Test Suite
#
# Tests Docker installation, images, containers, networking, volumes
################################################################################

# Strict mode
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$HOME/operation-shadow-docker"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

################################################################################
# Test utilities
################################################################################

test_start() {
    ((TESTS_RUN++))
    echo -e "${BLUE}[Test $TESTS_RUN]${NC} $1..."
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $1"
}

test_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

################################################################################
# Test Category 1: Docker Installation
################################################################################

test_docker_installation() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 1: Docker Installation"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 1.1: Docker command exists
    test_start "Docker command available"
    if command -v docker &> /dev/null; then
        test_pass "Docker command found: $(docker --version)"
    else
        test_fail "Docker NOT installed"
        echo "  Install: See Episode 14 README.md Task 1"
        return 1
    fi

    # Test 1.2: Docker daemon running
    test_start "Docker daemon running"
    if docker info &> /dev/null; then
        test_pass "Docker daemon is running"
    else
        test_fail "Docker daemon NOT running"
        echo "  Start: sudo systemctl start docker"
    fi

    # Test 1.3: Docker Compose available
    test_start "Docker Compose available"
    if docker compose version &> /dev/null; then
        test_pass "Docker Compose found: $(docker compose version --short)"
    else
        test_warning "Docker Compose NOT found (optional in Episode 14)"
    fi

    # Test 1.4: User in docker group
    test_start "User can run docker without sudo"
    if docker ps &> /dev/null; then
        test_pass "User can run Docker without sudo"
    else
        test_warning "User may need sudo for Docker"
        echo "  Fix: sudo usermod -aG docker \$USER && newgrp docker"
    fi
}

################################################################################
# Test Category 2: Project Structure
################################################################################

test_project_structure() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 2: Project Structure"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 2.1: Project directory exists
    test_start "Project directory exists"
    if [ -d "$PROJECT_DIR" ]; then
        test_pass "Project directory found: $PROJECT_DIR"
    else
        test_warning "Project directory NOT found (will be created)"
    fi

    # Test 2.2: Dockerfiles exist
    test_start "Dockerfiles created"
    DOCKERFILES_FOUND=0
    if [ -f "$PROJECT_DIR/web/Dockerfile" ]; then
        ((DOCKERFILES_FOUND++))
    fi
    if [ -f "$PROJECT_DIR/tool/Dockerfile" ]; then
        ((DOCKERFILES_FOUND++))
    fi

    if [ "$DOCKERFILES_FOUND" -ge 1 ]; then
        test_pass "Found $DOCKERFILES_FOUND Dockerfile(s)"
    else
        test_warning "No Dockerfiles found (complete Task 2)"
    fi

    # Test 2.3: docker-compose.yml exists
    test_start "docker-compose.yml exists"
    if [ -f "$PROJECT_DIR/compose/docker-compose.yml" ]; then
        test_pass "docker-compose.yml found"
    else
        test_warning "docker-compose.yml NOT found (complete Task 6)"
    fi

    # Test 2.4: Scripts directory
    test_start "Scripts directory exists"
    if [ -d "$PROJECT_DIR/scripts" ]; then
        test_pass "Scripts directory found"
    else
        test_warning "Scripts directory NOT found (complete Task 9)"
    fi
}

################################################################################
# Test Category 3: Docker Images
################################################################################

test_docker_images() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 3: Docker Images"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 3.1: Images exist
    test_start "Docker images built"
    IMAGE_COUNT=$(docker images -q | wc -l)
    if [ "$IMAGE_COUNT" -ge 1 ]; then
        test_pass "$IMAGE_COUNT Docker image(s) found"
    else
        test_warning "No Docker images found (build some images)"
    fi

    # Test 3.2: operation-shadow images
    test_start "Operation Shadow images exist"
    SHADOW_IMAGES=$(docker images --format "{{.Repository}}" | grep -c "operation-shadow" || echo "0")
    if [ "$SHADOW_IMAGES" -ge 1 ]; then
        test_pass "$SHADOW_IMAGES Operation Shadow image(s) built"
    else
        test_warning "No operation-shadow images (complete Task 2)"
    fi

    # Test 3.3: Alpine-based images (optimization check)
    test_start "Using Alpine-based images"
    ALPINE_COUNT=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -c "alpine" || echo "0")
    if [ "$ALPINE_COUNT" -ge 1 ]; then
        test_pass "$ALPINE_COUNT Alpine-based image(s) (good practice)"
    else
        test_warning "No Alpine images found (consider using Alpine for smaller size)"
    fi
}

################################################################################
# Test Category 4: Docker Containers
################################################################################

test_docker_containers() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 4: Docker Containers"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 4.1: Any containers exist
    test_start "Containers exist (running or stopped)"
    CONTAINER_COUNT=$(docker ps -a -q | wc -l)
    if [ "$CONTAINER_COUNT" -ge 1 ]; then
        test_pass "$CONTAINER_COUNT container(s) exist"
    else
        test_warning "No containers found (run some containers)"
    fi

    # Test 4.2: Running containers
    test_start "Running containers"
    RUNNING_COUNT=$(docker ps -q | wc -l)
    if [ "$RUNNING_COUNT" -ge 1 ]; then
        test_pass "$RUNNING_COUNT container(s) running"
        docker ps --format "table {{.Names}}\t{{.Status}}"
    else
        test_warning "No running containers (start some containers)"
    fi

    # Test 4.3: shadow-web container
    test_start "shadow-web container exists"
    if docker ps -a --format "{{.Names}}" | grep -q "shadow-web"; then
        STATUS=$(docker ps -a --format "{{.Names}}\t{{.Status}}" | grep shadow-web)
        test_pass "shadow-web found: $STATUS"
    else
        test_warning "shadow-web container NOT found (complete Task 2)"
    fi
}

################################################################################
# Test Category 5: Docker Networking
################################################################################

test_docker_networking() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 5: Docker Networking"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 5.1: Networks exist
    test_start "Docker networks exist"
    NETWORK_COUNT=$(docker network ls -q | wc -l)
    if [ "$NETWORK_COUNT" -ge 3 ]; then
        test_pass "$NETWORK_COUNT network(s) exist (including defaults)"
    else
        test_fail "Only $NETWORK_COUNT networks (default should be 3: bridge, host, none)"
    fi

    # Test 5.2: Custom network
    test_start "Custom network created"
    if docker network ls --format "{{.Name}}" | grep -qE "shadow-network|shadow-net"; then
        test_pass "Custom network found"
    else
        test_warning "No custom network found (complete Task 3)"
    fi

    # Test 5.3: Network connectivity test
    test_start "Network connectivity (if containers running)"
    if docker ps -q | head -1 | grep -q .; then
        CONTAINER=$(docker ps --format "{{.Names}}" | head -1)
        if docker exec "$CONTAINER" ping -c 1 8.8.8.8 &> /dev/null; then
            test_pass "Network connectivity works (tested with $CONTAINER)"
        else
            test_warning "Network connectivity test failed"
        fi
    else
        test_warning "No running containers to test connectivity"
    fi
}

################################################################################
# Test Category 6: Docker Volumes
################################################################################

test_docker_volumes() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 6: Docker Volumes"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 6.1: Volumes exist
    test_start "Docker volumes exist"
    VOLUME_COUNT=$(docker volume ls -q | wc -l)
    if [ "$VOLUME_COUNT" -ge 1 ]; then
        test_pass "$VOLUME_COUNT volume(s) created"
    else
        test_warning "No volumes found (complete Task 4)"
    fi

    # Test 6.2: shadow-data volume
    test_start "shadow-data volume exists"
    if docker volume ls --format "{{.Name}}" | grep -q "shadow-data"; then
        test_pass "shadow-data volume found"
    else
        test_warning "shadow-data volume NOT found (complete Task 4)"
    fi

    # Test 6.3: Compose volumes
    test_start "Docker Compose volumes"
    if docker volume ls --format "{{.Name}}" | grep -q "db-data"; then
        test_pass "Compose volumes found (db-data)"
    else
        test_warning "Compose volumes NOT found (complete Task 6)"
    fi
}

################################################################################
# Test Category 7: Docker Compose
################################################################################

test_docker_compose() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 7: Docker Compose"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 7.1: docker-compose.yml syntax
    test_start "docker-compose.yml syntax valid"
    if [ -f "$PROJECT_DIR/compose/docker-compose.yml" ]; then
        cd "$PROJECT_DIR/compose" && docker compose config &> /dev/null && cd - > /dev/null
        if [ $? -eq 0 ]; then
            test_pass "docker-compose.yml syntax is valid"
        else
            test_fail "docker-compose.yml has syntax errors"
        fi
    else
        test_warning "docker-compose.yml NOT found"
    fi

    # Test 7.2: Compose services running
    test_start "Docker Compose services running"
    if [ -f "$PROJECT_DIR/compose/docker-compose.yml" ]; then
        cd "$PROJECT_DIR/compose"
        RUNNING_SERVICES=$(docker compose ps --services --filter "status=running" 2>/dev/null | wc -l)
        cd - > /dev/null
        if [ "$RUNNING_SERVICES" -ge 1 ]; then
            test_pass "$RUNNING_SERVICES Compose service(s) running"
        else
            test_warning "No Compose services running (run: docker compose up -d)"
        fi
    else
        test_warning "docker-compose.yml NOT found"
    fi
}

################################################################################
# Test Category 8: Security
################################################################################

test_security() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 8: Security"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 8.1: Trivy installed
    test_start "Trivy security scanner installed"
    if command -v trivy &> /dev/null; then
        test_pass "Trivy installed: $(trivy --version | head -1)"
    else
        test_warning "Trivy NOT installed (optional but recommended)"
        echo "  Install: sudo apt install trivy"
    fi

    # Test 8.2: No images running as root (security check)
    test_start "Container security check"
    ROOT_CONTAINERS=$(docker ps --format "{{.Names}}" | while read container; do
        docker exec "$container" whoami 2>/dev/null | grep -q "^root$" && echo "$container"
    done | wc -l)

    if [ "$ROOT_CONTAINERS" -eq 0 ]; then
        test_pass "No containers running as root (good!)"
    else
        test_warning "$ROOT_CONTAINERS container(s) running as root (consider non-root user)"
    fi

    # Test 8.3: Audit script exists
    test_start "Docker audit script exists"
    if [ -f "$PROJECT_DIR/scripts/docker_audit.sh" ]; then
        test_pass "docker_audit.sh found"
        if [ -x "$PROJECT_DIR/scripts/docker_audit.sh" ]; then
            test_pass "docker_audit.sh is executable"
        else
            test_warning "docker_audit.sh NOT executable (chmod +x)"
        fi
    else
        test_warning "docker_audit.sh NOT found (complete Task 9)"
    fi
}

################################################################################
# Test Category 9: Best Practices
################################################################################

test_best_practices() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 9: Docker Best Practices"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 9.1: Multi-stage build used
    test_start "Multi-stage Dockerfile exists"
    if [ -f "$PROJECT_DIR/tool/Dockerfile" ]; then
        if grep -q "AS builder" "$PROJECT_DIR/tool/Dockerfile"; then
            test_pass "Multi-stage build detected (good practice)"
        else
            test_warning "Multi-stage build NOT detected (complete Task 5)"
        fi
    else
        test_warning "tool/Dockerfile NOT found (complete Task 5)"
    fi

    # Test 9.2: Health checks in Dockerfile
    test_start "Health checks configured"
    HEALTHCHECK_COUNT=$(find "$PROJECT_DIR" -name "Dockerfile" -exec grep -l "HEALTHCHECK" {} \; 2>/dev/null | wc -l)
    if [ "$HEALTHCHECK_COUNT" -ge 1 ]; then
        test_pass "$HEALTHCHECK_COUNT Dockerfile(s) with HEALTHCHECK"
    else
        test_warning "No HEALTHCHECK found (add for production readiness)"
    fi

    # Test 9.3: .dockerignore exists
    test_start ".dockerignore file exists"
    DOCKERIGNORE_COUNT=$(find "$PROJECT_DIR" -name ".dockerignore" 2>/dev/null | wc -l)
    if [ "$DOCKERIGNORE_COUNT" -ge 1 ]; then
        test_pass ".dockerignore found (good practice)"
    else
        test_warning ".dockerignore NOT found (create to exclude unnecessary files)"
    fi

    # Test 9.4: Docker system disk usage
    test_start "Docker disk usage reasonable"
    DOCKER_SIZE=$(docker system df --format "{{.Size}}" | head -1 | grep -oE "[0-9.]+" | head -1)
    if [ -n "$DOCKER_SIZE" ]; then
        test_pass "Docker using disk space (check with: docker system df)"
    else
        test_warning "Cannot determine Docker disk usage"
    fi
}

################################################################################
# Final Summary
################################################################################

print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Total tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Tests failed:${NC} $TESTS_FAILED"
    echo ""

    PASS_RATE=$(( TESTS_PASSED * 100 / TESTS_RUN ))

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✓ ALL TESTS PASSED! ($PASS_RATE%)${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Excellent work! Your Docker environment is properly configured."
        echo ""
        echo "Quick reference:"
        echo "  docker ps                    # List running containers"
        echo "  docker images                # List images"
        echo "  docker logs shadow-web       # View container logs"
        echo "  docker exec -it shadow-web sh  # Shell into container"
        echo ""
        echo "Next: Episode 15 (CI/CD Pipelines) — Berlin"
        return 0
    elif [ "$PASS_RATE" -ge 70 ]; then
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  ⚠ TESTS MOSTLY PASSED ($PASS_RATE%)${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Good progress! Fix remaining issues above."
        return 1
    else
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}  ✗ TESTS FAILED ($PASS_RATE%)${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Review failed tests above and fix issues."
        echo "See Episode 14 README.md for detailed instructions."
        return 1
    fi
}

################################################################################
# Main execution
################################################################################

main() {
    echo ""
    echo "################################################################"
    echo "  KERNEL SHADOWS: Episode 14 — Docker Basics"
    echo "  Test Suite"
    echo "################################################################"
    echo ""

    # Run all test categories
    test_docker_installation || true
    test_project_structure || true
    test_docker_images || true
    test_docker_containers || true
    test_docker_networking || true
    test_docker_volumes || true
    test_docker_compose || true
    test_security || true
    test_best_practices || true

    # Print summary
    print_summary
}

# Run main
main "$@"


