#!/bin/bash

################################################################################
# KERNEL SHADOWS: Episode 15 — Deployment Script
# Blue-Green Deployment with Zero Downtime
# Berlin, Germany (Day 29-30)
#
# This script is called FROM CI/CD pipeline, not a wrapper around it!
# "CI/CD pipelines exist → use them, don't wrap them" — Type B philosophy
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
ENVIRONMENT=""
IMAGE=""
SERVER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment) ENVIRONMENT="$2"; shift 2 ;;
        --image) IMAGE="$2"; shift 2 ;;
        --server) SERVER="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate
if [[ -z "$ENVIRONMENT" || -z "$IMAGE" || -z "$SERVER" ]]; then
    echo "Usage: $0 --environment ENV --image IMAGE --server SERVER"
    exit 1
fi

echo -e "${BLUE}Deploying to $ENVIRONMENT...${NC}"
echo "Image: $IMAGE"
echo "Server: $SERVER"

################################################################################
# Blue-Green Deployment (Zero Downtime)
################################################################################

echo -e "${YELLOW}Step 1: Pull new image...${NC}"
ssh deploy@"$SERVER" "docker pull $IMAGE"

echo -e "${YELLOW}Step 2: Stop old container (keep as backup)...${NC}"
ssh deploy@"$SERVER" "docker stop operation-shadow-old 2>/dev/null || true"
ssh deploy@"$SERVER" "docker rename operation-shadow operation-shadow-old 2>/dev/null || true"

echo -e "${YELLOW}Step 3: Start new container...${NC}"
ssh deploy@"$SERVER" "docker run -d \
    --name operation-shadow \
    -p 80:80 \
    --restart unless-stopped \
    --env-file /opt/operation-shadow/.env \
    $IMAGE"

echo -e "${YELLOW}Step 4: Health check...${NC}"
sleep 10
if ssh deploy@"$SERVER" "curl -f http://localhost/health"; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed! Rolling back...${NC}"
    ssh deploy@"$SERVER" "docker stop operation-shadow && docker rm operation-shadow"
    ssh deploy@"$SERVER" "docker rename operation-shadow-old operation-shadow"
    ssh deploy@"$SERVER" "docker start operation-shadow"
    exit 1
fi

echo -e "${YELLOW}Step 5: Cleanup old container...${NC}"
ssh deploy@"$SERVER" "docker rm operation-shadow-old 2>/dev/null || true"

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo -e "${GREEN}Environment: $ENVIRONMENT${NC}"
echo -e "${GREEN}Image: $IMAGE${NC}"
echo -e "${GREEN}=========================================${NC}"

################################################################################
# Hans's Deployment Philosophy:
#
# "Zero downtime deployment:
#  1. Keep old container as backup (rename, don't remove)
#  2. Start new container
#  3. Health check (10s wait + curl)
#  4. If fail → automatic rollback
#  5. If success → remove old container
#
#  That's how you deploy without fear."
################################################################################


