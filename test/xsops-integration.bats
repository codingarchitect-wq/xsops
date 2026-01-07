#!/usr/bin/env bats
# tests/secrets.bats

setup() {
    TEST_DIR="$(mktemp -d)"
    echo "Created test dir $TEST_DIR"
    export TEST_DIR

    # Use GPG fingerprint from environment (set by test runner)
    if [[ -z "${GPG_FP:-}" ]]; then
        echo "Error: GPG_FP environment variable not set. Run tests via run-integration-tests.sh" >&2
        return 1
    fi
    
    # Create project structure
    mkdir -p "$TEST_DIR/project/secrets/dev"
    mkdir -p "$TEST_DIR/project/secrets/prod"
    mkdir -p "$TEST_DIR/project/src/nested"
    
    # Create .sops.yaml
    cat > "$TEST_DIR/project/.sops.yaml" <<EOF
creation_rules:
  - path_regex: .*\.yaml$
    pgp: $GPG_FP
EOF

    # Create and encrypt secrets
    cat > "$TEST_DIR/project/secrets/dev/env.yaml" <<EOF
TEST_KEY: dev-value
ANOTHER_KEY: another-dev-value
EOF

    cat > "$TEST_DIR/project/secrets/prod/env.yaml" <<EOF
TEST_KEY: prod-value
ANOTHER_KEY: another-prod-value
EOF

    cd "$TEST_DIR/project"
    sops -e -i secrets/dev/env.yaml
    sops -e -i secrets/prod/env.yaml

    echo "Encrypted dev secrets file:"
    cat "$TEST_DIR/project/secrets/dev/env.yaml"
    
    # Copy actual script
    cp "$BATS_TEST_DIRNAME/../xsops" "$TEST_DIR/xsops"
    chmod +x "$TEST_DIR/xsops"
}

teardown() {
    echo "Removing test dir $TEST_DIR"
    rm -rf "$TEST_DIR"
    echo "Removed test dir $TEST_DIR"
}

# --- Run command ---

@test "run loads dev secrets" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" run dev -- printenv TEST_KEY
    [ "$status" -eq 0 ]
    [ "$output" = "dev-value" ]
}

@test "run loads prod secrets" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" run prod -- printenv TEST_KEY
    [ "$status" -eq 0 ]
    [ "$output" = "prod-value" ]
}

@test "run loads multiple secrets" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" run dev -- printenv ANOTHER_KEY
    [ "$status" -eq 0 ]
    [ "$output" = "another-dev-value" ]
}

@test "run works from nested directory" {
    cd "$TEST_DIR/project/src/nested"
    run "$TEST_DIR/xsops" run dev -- printenv TEST_KEY
    [ "$status" -eq 0 ]
    [ "$output" = "dev-value" ]
}

@test "run fails for nonexistent environment" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" run staging -- echo hello
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Secrets file not found" ]]
}

@test "run executes command without secrets" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" run dev -- echo hello world
    [ "$status" -eq 0 ]
    [ "$output" = "hello world" ]
}

@test "run executes command with secret referenced in args" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" run dev -- echo '$TEST_KEY'
    [ "$status" -eq 0 ]
    [ "$output" = "dev-value" ]
}

@test "secrets not in environment after run with secret in args" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" run dev -- echo '$TEST_KEY'
    [ "$status" -eq 0 ]
    [ "$output" = "dev-value" ]
    run printenv TEST_KEY
    [ "$status" -eq 1 ]
}

@test "secrets not in environment after run" {
    cd "$TEST_DIR/project"
    "$TEST_DIR/xsops" run dev -- echo "done"
    run printenv TEST_KEY
    [ "$status" -eq 1 ]
}

# --- View command ---

@test "view shows decrypted secrets" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" view dev
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TEST_KEY" ]]
    [[ "$output" =~ "dev-value" ]]
}

# --- Which command ---

@test "which shows correct paths for dev" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" which dev
    [ "$status" -eq 0 ]
    [[ "$output" =~ "secrets/dev/env.yaml" ]]
}

@test "which shows correct paths for prod" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" which prod
    [ "$status" -eq 0 ]
    [[ "$output" =~ "secrets/prod/env.yaml" ]]
}