#!/bin/bash
# KERNEL SHADOWS: Episode 15 — CI/CD Pipelines
# Simple deployment helper script

set -e

SERVER="${1:-localhost}"
IMAGE="${2:-operation-shadow/app:latest}"
PORT="${3:-80}"

echo "Deploying to $SERVER..."
echo "Image: $IMAGE"
echo "Port: $PORT"

# Pull image
ssh deploy@"$SERVER" "docker pull $IMAGE"

# Blue-green deployment
ssh deploy@"$SERVER" "docker stop operation-shadow-old || true"
ssh deploy@"$SERVER" "docker rename operation-shadow operation-shadow-old || true"
ssh deploy@"$SERVER" "docker run -d --name operation-shadow -p $PORT:80 $IMAGE"

# Health check
sleep 5
if curl -f "http://$SERVER/health"; then
    echo "✓ Deployment successful"
    ssh deploy@"$SERVER" "docker rm operation-shadow-old || true"
else
    echo "✗ Health check failed, rolling back..."
    ssh deploy@"$SERVER" "docker stop operation-shadow"
    ssh deploy@"$SERVER" "docker rename operation-shadow-old operation-shadow"
    ssh deploy@"$SERVER" "docker start operation-shadow"
    exit 1
fi

