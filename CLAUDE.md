# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`xsops` is a bash helper script for working with SOPS-encrypted secrets files across different environments (dev, prod, etc.). It wraps SOPS commands to load, view, and edit encrypted environment-specific secrets.

## Commands

```bash
# Install dependencies
npm install

# Run unit tests (uses mocked SOPS)
npm test

# Run integration tests in Docker (uses real SOPS + GPG)
npm run test:integration

# Run unit tests with verbose output
npm run debug-test

# Run a single test file
npx bats test/xsops-unit.bats
```

## Architecture

### Main Script (`xsops`)
Bash script that:
- Finds project root by walking up looking for `.sops.yaml` or `secrets/` directory
- Supports commands: `run`, `edit`, `view`, `which`
- Uses `sops exec-env` to inject decrypted secrets into command environment

### Test Structure
- **Unit tests** (`test/xsops-unit.bats`): Use a mocked SOPS implementation (plain YAML parsing) for fast, dependency-free testing
- **Integration tests** (`test/xsops-integration.bats`): Run in Docker with real SOPS and an ephemeral GPG key generated at test startup

### Integration Test Docker Setup
- `test/Dockerfile`: Alpine image with SOPS, GPG, bats-core
- `test/generate-test-gpg-key.sh`: Creates ephemeral GPG key, outputs fingerprint
- `test/run-integration-tests.sh`: Container entrypoint that sets up GPG and runs bats
- `test/docker-test.sh`: Host script to build and run the test container
