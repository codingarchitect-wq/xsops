# xsops

A CLI helper for running commands with SOPS-encrypted secrets injected as environment variables, without leaking them into the global shell environment or in files.

This is useful for managing per-environment secrets (dev, prod, etc.) in a secure way and not worrying about accidentally exposing them in environment variables or .env files when running AI coding agents.

## What It Does

This script simplifies working with per-environment encrypted secrets. It acts as a opinionated convenience wrapper for `sops` commands, so you can:

- Run any command with secrets loaded into its environment
  - It relies on the sops `exec-env` command to decrypt secrets on-the-fly and pass them to the command being run. See the [SOPS exec-env documentation](https://github.com/getsops/sops?tab=readme-ov-file#passing-secrets-to-other-processes) for more details.
- View decrypted secrets without creating temporary files
- Edit encrypted secrets in your default editor
- Work from any subdirectory—the script finds the project root automatically

Secrets never leak into your shell's environment; they're only available to the command you run.

## Prerequisites

- [SOPS](https://github.com/getsops/sops) installed and configured
- GPG (plain or backed-up by YubiKey) or Age keys set up for encryption/decryption
- A `.sops.yaml` configuration file in your project root

## Installation

```bash
# Clone the repository
git clone https://github.com/codingarchitect-wq/xsops.git
cd xsops
```

### Linux / macOS

```bash
# Option 1: Symlink to /usr/local/bin (requires sudo)
sudo ln -s "$(pwd)/xsops" /usr/local/bin/xsops

# Option 2: Add to PATH in ~/.bashrc or ~/.zshrc (no sudo required)
echo "export PATH=\"\$PATH:$(pwd)\"" >> ~/.bashrc
source ~/.bashrc
```

### Windows (WSL)

```bash
# Same as Linux - run from within WSL
sudo ln -s "$(pwd)/xsops" /usr/local/bin/xsops
```

### Windows (Git Bash)

Symlinks are unreliable in Git Bash. Add the directory to your PATH instead:

```bash
# Add to ~/.bashrc
echo "export PATH=\"\$PATH:$(pwd)\"" >> ~/.bashrc
source ~/.bashrc
```

To verify installation, run:

```bash
xsops
```

## Project Structure

The script expects your projects to have this structure:

```
your-project/
├── .sops.yaml              # SOPS configuration
└── secrets/
    ├── dev/
    │   └── env.yaml        # Encrypted secrets for dev
    └── prod/
        └── env.yaml        # Encrypted secrets for prod
```

`dev` and `prod` are environment names you can define as you like.

Example `.sops.yaml` using both PGP (plain or stored on YubiKey) and Azure Key Vault keys:

```yaml
# .sops.yaml
stores:
  yaml:
    indent: 2

creation_rules:  
  # Dev secrets
  - path_regex: secrets/dev01/.*\.yaml$
    pgp:
      - PGP_KEY_ID_HERE
    azure_keyvault:
      - https://devkeyvaultname.vault.azure.net/keys/keyname/version

  # Prod secrets
  - path_regex: secrets/prod/.*\.yaml$
    pgp:
      - PGP_KEY_ID_HERE
    azure_keyvault:
      - https://prodkeyvaultname.vault.azure.net/keys/keyname/version
```

Example `secrets/dev/env.yaml` (before encryption):

```yaml
DATABASE_URL: postgres://localhost/myapp_dev
API_KEY: dev-secret-key
```

Encrypt with: `sops -e -i secrets/dev/env.yaml`

## Usage

### Run a command with secrets

```bash
# Run a Node.js app with dev secrets
xsops run dev -- node server.js

# Run database migrations with prod secrets
xsops run prod -- npm run migrate

# Use secrets in a shell command
xsops run dev -- sh -c 'echo $DATABASE_URL'
```

### View decrypted secrets

```bash
xsops view dev
```

### Edit secrets

Opens the decrypted file in your editor; re-encrypts on save:

```bash
xsops edit dev
```

### Show resolved paths

```bash
xsops which dev
# Output:
# Project root: /path/to/your-project
# Secrets file: /path/to/your-project/secrets/dev/env.yaml
```

## Development

```bash
# Install test dependencies (bats for bash testing)
npm install

# Run unit tests
npm test

# Run integration tests (requires Docker since it creates a docker container to test with real SOPS + GPG)
npm run test:integration

# Run unit tests with verbose output
npm run debug-test
```


## FAQ

### Does the script work on Windows?

The script is bash-only and won't run natively on Windows. It requires:

  - Bash shell (#!/bin/bash)
  - Unix utilities (dirname, etc.)
  - Bash-specific syntax ([[ ]], set -euo pipefail)

Windows options:
| Method                            | Works? |
|-----------------------------------|--------|
| Native CMD/PowerShell             | No     |
| WSL (Windows Subsystem for Linux) | Yes    |
| Git Bash                          | Yes    |
| Cygwin/MSYS2                      | Yes    |

So Windows users can use it through WSL or Git Bash, but it's not a native Windows solution. If you need native Windows support, you'd need a PowerShell port or a cross-platform rewrite (e.g., in Python or Node.js).