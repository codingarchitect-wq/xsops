#!/bin/bash
# Build and run integration tests in Docker
# Usage: ./test/docker-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

IMAGE_NAME="xsops-test"

echo "==> Building test Docker image..."
docker build -t "$IMAGE_NAME" -f test/Dockerfile .

echo "==> Running integration tests in Docker..."
docker run --rm "$IMAGE_NAME"
