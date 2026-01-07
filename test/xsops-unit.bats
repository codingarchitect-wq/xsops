#!/usr/bin/env bats
# tests/xsops-unit.bats

setup() {
    TEST_DIR="$(mktemp -d)"
    echo "Created test dir $TEST_DIR"
    export TEST_DIR
    
    # Create project structure
    mkdir -p "$TEST_DIR/project/secrets/dev"
    mkdir -p "$TEST_DIR/project/secrets/prod"
    mkdir -p "$TEST_DIR/project/src/nested"
    
    # Create .sops.yaml marker
    touch "$TEST_DIR/project/.sops.yaml"
    
    # Create test secrets (plain yaml for testing - mock sops below)
    cat > "$TEST_DIR/project/secrets/dev/env.yaml" <<EOF
TEST_KEY: dev-value
ANOTHER_KEY: another-dev-value
EOF

    cat > "$TEST_DIR/project/secrets/prod/env.yaml" <<EOF
TEST_KEY: prod-value
ANOTHER_KEY: another-prod-value
EOF

    # Create script with mocked sops for testing
    cat > "$TEST_DIR/xsops" <<'SCRIPT'
#!/bin/bash
set -euo pipefail

find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.sops.yaml" ]] || [[ -d "$dir/secrets" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

PROJECT_ROOT="$(find_project_root)" || {
    echo "Error: Could not find project root (no .sops.yaml or secrets/ directory found)"
    exit 1
}

usage() {
    echo "Usage: secrets <command> <env> [-- <cmd>]"
    echo ""
    echo "Commands:"
    echo "  run <env> -- <cmd>    Run command with secrets loaded"
    echo "  edit <env>            Edit secrets file"
    echo "  view <env>            View decrypted secrets"
    echo "  which <env>           Show resolved paths"
    echo ""
    echo "Environments: dev, prod"
    echo "Detected project: $PROJECT_ROOT"
}

CMD="${1:-}"
ENV="${2:-}"

if [[ -z "$CMD" ]]; then
    usage
    exit 1
fi

if [[ -z "$ENV" ]]; then
    echo "Error: Environment required (dev, prod)"
    exit 1
fi

SECRETS_FILE="$PROJECT_ROOT/secrets/${ENV}/env.yaml"

if [[ ! -f "$SECRETS_FILE" && "$CMD" != "which" ]]; then
    echo "Error: Secrets file not found: $SECRETS_FILE"
    exit 1
fi

case "$CMD" in
    run)
        shift 2
        [[ "${1:-}" == "--" ]] && shift
        # Mock sops exec-env: source yaml as env vars
        set -a
        eval "$(sed 's/: /=/' "$SECRETS_FILE")"
        set +a
        exec "${@}"
        ;;
    edit)
        echo "Would edit: $SECRETS_FILE"
        ;;
    view)
        cat "$SECRETS_FILE"
        ;;
    which)
        echo "Project root: $PROJECT_ROOT"
        echo "Secrets file: $SECRETS_FILE"
        ;;
    *)
        usage
        exit 1
        ;;
esac
SCRIPT
    chmod +x "$TEST_DIR/xsops"
}

teardown() {
    echo "Removing test dir $TEST_DIR"
    rm -rf "$TEST_DIR"
    echo "Removed test dir $TEST_DIR"
}

# --- Usage tests ---

@test "shows usage when no command given" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "shows error when env not given" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" run
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Environment required" ]]
}

@test "shows error for unknown command" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" unknown dev
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

# --- Project root detection ---

@test "finds project root from project directory" {
    cd "$TEST_DIR/project"
    run "$TEST_DIR/xsops" which dev
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Project root: $TEST_DIR/project" ]]
}

@test "finds project root from nested directory" {
    cd "$TEST_DIR/project/src/nested"
    run "$TEST_DIR/xsops" which dev
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Project root: $TEST_DIR/project" ]]
}

@test "fails when no project root found" {
    cd "/tmp"
    run "$TEST_DIR/xsops" which dev
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Could not find project root" ]]
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
