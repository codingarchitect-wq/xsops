#!/bin/bash
# Runs integration tests with an ephemeral GPG key
# This script is the entrypoint for the Docker container

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Setting up ephemeral GPG environment..."

# Create isolated GNUPGHOME for tests
export GNUPGHOME="$(mktemp -d)"
chmod 700 "$GNUPGHOME"

cleanup() {
    echo "==> Cleaning up GPG home..."
    rm -rf "$GNUPGHOME"
}
trap cleanup EXIT

echo "==> Generating test GPG key..."
export GPG_FP=$("$SCRIPT_DIR/generate-test-gpg-key.sh")
echo "    Generated key with fingerprint: $GPG_FP"

echo "==> Running integration tests..."
bats "$SCRIPT_DIR/xsops-integration.bats"
