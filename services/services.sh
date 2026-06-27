#!/usr/bin/env bash
set -euo pipefail

SERVICES_DIR="$(cd "$(dirname "$0")" && pwd)"
WAIT_TIMEOUT=180
WAIT_INTERVAL=5

usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --start   Start all services, wait for containers to be ready, then run health check"
    echo "  --stop    Stop all services"
    echo "  --health  Wait for containers to be ready and run health check"
    echo "  --help    Show this help message"
    exit 0
}

wait_for_containers() {
    local elapsed=0
    echo "Waiting for containers to be ready (timeout: ${WAIT_TIMEOUT}s)..."

    while [[ $elapsed -lt $WAIT_TIMEOUT ]]; do
        local starting
        starting=$(docker ps \
            --filter "label=homelab.monitor=true" \
            --format '{{if .State}}{{end}}{{.Names}}' 2>/dev/null \
            | xargs -r -I{} docker inspect \
                --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' {} \
            | grep -c "^starting$" 2>/dev/null || true)

        if [[ "$starting" -eq 0 ]]; then
            echo "All containers have passed their start period."
            echo ""
            return
        fi

        echo "  ${starting} container(s) still starting... (${elapsed}s elapsed)"
        sleep "$WAIT_INTERVAL"
        elapsed=$(( elapsed + WAIT_INTERVAL ))
    done

    echo "Timeout reached — some containers may still be starting."
    echo ""
}

[[ $# -eq 1 ]] || usage

case "$1" in
    --start)
        # Required by watchtower
        export DOCKER_API_VERSION
        DOCKER_API_VERSION=$(docker version --format '{{.Server.APIVersion}}')

        for dir in "$SERVICES_DIR"/*/; do
            [[ -f "$dir/docker-compose.yml" ]] || continue
            echo "Starting $(basename "$dir")..."
            docker compose -f "$dir/docker-compose.yml" up -d
            echo ""
        done

        wait_for_containers
        bash "$SERVICES_DIR/checks-after-reboot.sh"
        ;;
    --stop)
        for dir in "$SERVICES_DIR"/*/; do
            [[ -f "$dir/docker-compose.yml" ]] || continue
            echo "Stopping $(basename "$dir")..."
            docker compose -f "$dir/docker-compose.yml" down
            echo ""
        done

        echo "All services stopped."
        ;;
    --health)
        wait_for_containers
        bash "$SERVICES_DIR/checks-after-reboot.sh"
        ;;
    --help)
        usage
        ;;
    *)
        echo "Unknown option: $1"
        echo ""
        usage
        ;;
esac
