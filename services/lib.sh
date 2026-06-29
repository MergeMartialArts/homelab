#!/usr/bin/env bash
# Sourced by service setup scripts — not executed directly.
# Sets SERVICES_DIR so callers don't need to navigate with relative paths.

SERVICES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "ERROR: docker is not installed or not in PATH."
        exit 1
    fi
    if ! docker info &>/dev/null; then
        echo "ERROR: Cannot connect to Docker. Make sure Docker is running and your user is in the 'docker' group."
        exit 1
    fi
}

# Copy .env.example → .env if missing, list placeholders, then exit so the
# user can fill them in before re-running setup.
ensure_env() {
    local dir="$1"
    if [[ -f "$dir/.env" ]]; then
        return
    fi

    cp "$dir/.env.example" "$dir/.env"
    echo "Created: $dir/.env"
    echo ""

    local placeholders=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ =change-me$ ]] && placeholders+=("  ${line%%=*}")
    done < "$dir/.env"

    if [[ ${#placeholders[@]} -gt 0 ]]; then
        echo "Set these values before continuing:"
        printf '%s\n' "${placeholders[@]}"
        echo ""
        echo "Edit $dir/.env then re-run setup."
        exit 1
    fi
}

# Fail if any value in .env is still the change-me placeholder.
validate_env() {
    local dir="$1"
    local errors=()

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ =change-me$ ]] && errors+=("  ${line%%=*}")
    done < "$dir/.env"

    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "ERROR: Replace all change-me placeholders in $dir/.env:"
        printf '%s\n' "${errors[@]}"
        exit 1
    fi
}
