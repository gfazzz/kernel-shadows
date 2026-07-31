#!/bin/bash

################################################################################
# KERNEL SHADOWS: Episode 14 — Docker Basics
# MINIMAL Docker Helper Script (Type B Approach!)
#
# Philosophy: "docker-compose exists → use it, don't wrap it"
# This script is ONLY a convenience wrapper for docker-compose commands
# Real work is done by Docker configs (Dockerfile, docker-compose.yml)
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR" || exit 1

# ============================================================================
# Helper Functions (MINIMAL!)
# ============================================================================

usage() {
    cat << EOF
Usage: $0 {up|down|restart|logs|status|clean}

Commands:
  up       - Start all containers (docker-compose up -d)
  down     - Stop all containers (docker-compose down)
  restart  - Restart containers
  logs     - Show container logs
  status   - Show container status
  clean    - Remove all containers, volumes, images

This is a MINIMAL wrapper. For advanced usage, use docker-compose directly:
  docker-compose up -d
  docker-compose logs -f web
  docker-compose exec web sh

EOF
    exit 1
}

# ============================================================================
# Main Commands (just docker-compose wrappers!)
# ============================================================================

case "${1:-}" in
    up)
        echo -e "${BLUE}Starting Operation Shadow containers...${NC}"
        docker-compose up -d
        echo -e "${GREEN}✓ Containers started${NC}"
        echo ""
        echo "Access services:"
        echo "  Web:        http://localhost:8080"
        echo "  Monitoring: http://localhost:3000 (admin/check secrets/)"
        ;;

    down)
        echo -e "${YELLOW}Stopping containers...${NC}"
        docker-compose down
        echo -e "${GREEN}✓ Containers stopped${NC}"
        ;;

    restart)
        echo -e "${YELLOW}Restarting containers...${NC}"
        docker-compose restart
        echo -e "${GREEN}✓ Containers restarted${NC}"
        ;;

    logs)
        docker-compose logs -f "${2:-}"
        ;;

    status)
        docker-compose ps
        echo ""
        docker-compose top
        ;;

    clean)
        echo -e "${YELLOW}⚠️  This will remove ALL containers, volumes, and images!${NC}"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down -v
            docker system prune -af
            echo -e "${GREEN}✓ Cleanup complete${NC}"
        fi
        ;;

    *)
        usage
        ;;
esac

################################################################################
# Type B Philosophy:
#
# This script is ~80 lines (vs 657 lines in old docker_setup.sh!)
# Why? Because Docker and docker-compose EXIST.
#
# Real configuration is in:
#   - Dockerfile (image definition)
#   - docker-compose.yml (orchestration)
#   - nginx.conf (web server config)
#   - configs/app.env (environment)
#
# This script = convenience wrapper ONLY.
# Learn docker-compose, don't hide it behind bash!
#
# "docker-compose exists → use it, don't rewrite it" — Episode 04 philosophy
################################################################################


