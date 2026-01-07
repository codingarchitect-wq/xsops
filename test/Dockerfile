FROM alpine:3.23.2

# Install dependencies
RUN apk add --no-cache \
    bash \
    gnupg \
    curl \
    coreutils \
    && rm -rf /var/cache/apk/*

# Install SOPS
ARG SOPS_VERSION=3.8.1
RUN curl -Lo /usr/local/bin/sops \
    "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64" \
    && chmod +x /usr/local/bin/sops

# Install bats-core
ARG BATS_VERSION=1.10.0
RUN curl -Lo /tmp/bats.tar.gz \
    "https://github.com/bats-core/bats-core/archive/refs/tags/v${BATS_VERSION}.tar.gz" \
    && tar -xzf /tmp/bats.tar.gz -C /tmp \
    && /tmp/bats-core-${BATS_VERSION}/install.sh /usr/local \
    && rm -rf /tmp/bats*

WORKDIR /app

# Copy test files and scripts
COPY . /app/

# Make scripts executable
RUN chmod +x /app/with-env-secrets /app/test/*.sh 2>/dev/null || true

ENTRYPOINT ["/app/test/run-integration-tests.sh"]
