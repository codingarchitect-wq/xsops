#!/bin/bash
# Generates an ephemeral GPG key for testing and outputs the fingerprint

set -euo pipefail

# Create a temporary GNUPGHOME to avoid polluting the user's keyring
export GNUPGHOME="${GNUPGHOME:-$(mktemp -d)}"

# Ensure proper permissions for GPG
chmod 700 "$GNUPGHOME"

# Generate key using batch mode (no passphrase, no expiration for test key)
gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: Test Key
Name-Email: test@example.com
Expire-Date: 0
%commit
EOF

# Get the fingerprint of the generated key
GPG_FP=$(gpg --list-keys --with-colons "test@example.com" 2>/dev/null | grep '^fpr' | head -1 | cut -d: -f10)

if [[ -z "$GPG_FP" ]]; then
    echo "Error: Failed to generate GPG key" >&2
    exit 1
fi

echo "$GPG_FP"
