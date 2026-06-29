#!/usr/bin/env bash
set -euo pipefail

SERVICES_DIR="$(cd "$(dirname "$0")" && pwd)"
WAIT_TIMEOUT=180
WAIT_INTERVAL=5

usage() {
    echo "Usage: $0 [OPTION] [--SERVICE]"
    echo ""
    echo "Options:"
    echo "  --start          Start all services (or a single service), wait for containers, then run health check"
    echo "  --stop           Stop all services (or a single service)"
    echo "  --setup          Run setup.sh for all services (or a single service)"
    echo "  --health         Wait for containers to be ready and run health check"
    echo "  --show-running   List all running containers by homelab.service label"
    echo "  --show-services  List all available services"
    echo "  --help           Show this help message"
    echo ""
    echo "Scope:"
    echo "  --all            Explicit all services (default when no service is given)"
    echo ""
    echo "Docker services (start, stop, setup):"
    for dir in "$SERVICES_DIR"/*/; do
        [[ -f "$dir/docker-compose.yml" ]] || continue
        echo "  --$(basename "$dir")"
    done
    echo ""
    echo "Setup-only services (setup):"
    for dir in "$SERVICES_DIR"/*/; do
        [[ -f "$dir/docker-compose.yml" ]] && continue
        [[ -f "$dir/setup.sh" ]] || continue
        echo "  --$(basename "$dir")"
    done
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

check_health() {
    echo "Health check:"
    echo ""

    local all_healthy=true

    while IFS= read -r name; do
        [[ -n "$name" ]] || continue

        local status
        status=$(docker inspect \
            --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
            "$name" 2>/dev/null || echo "not found")

        local symbol
        case "$status" in
            healthy|running) symbol="✓" ;;
            unhealthy)       symbol="✗"; all_healthy=false ;;
            *)               symbol="?"; all_healthy=false ;;
        esac

        printf "  %s  %-40s %s\n" "$symbol" "$name" "$status"
    done < <(docker ps \
        --filter "label=homelab.monitor=true" \
        --format "{{.Names}}" 2>/dev/null)

    echo ""

    if $all_healthy; then
        echo "All services healthy."
    else
        echo "Some services are not healthy."
        exit 1
    fi
}

ACTION=""
SERVICE_FILTER=""

for arg in "$@"; do
    case "$arg" in
        --start|--stop|--setup|--health|--help|--show-services|--show-running)
            ACTION="$arg"
            ;;
        --all)
            SERVICE_FILTER=""
            ;;
        --*)
            SERVICE_FILTER="${arg#--}"
            ;;
        *)
            echo "Unknown option: $arg"
            echo ""
            usage
            ;;
    esac
done

[[ -n "$ACTION" ]] || usage

if [[ -n "$SERVICE_FILTER" ]]; then
    case "$ACTION" in
        --setup)
            required="setup.sh"
            ;;
        *)
            required="docker-compose.yml"
            ;;
    esac

    if [[ ! -f "$SERVICES_DIR/$SERVICE_FILTER/$required" ]]; then
        echo "Unknown service: $SERVICE_FILTER"
        echo ""
        echo "Available services:"
        for dir in "$SERVICES_DIR"/*/; do
            [[ -f "$dir/$required" ]] || continue
            echo "  --$(basename "$dir")"
        done
        exit 1
    fi
fi

run_for_services() {
    local label="$1"
    local skip_start_last="${2:-}"
    shift 2
    for dir in "$SERVICES_DIR"/*/; do
        [[ -f "$dir/docker-compose.yml" ]] || continue
        local service
        service="$(basename "$dir")"
        [[ -z "$SERVICE_FILTER" || "$service" == "$SERVICE_FILTER" ]] || continue
        # Skip stop-all services (api, frontend) unless explicitly targeted
        [[ -z "$SERVICE_FILTER" && -f "$dir/.skip-all" ]] && continue
        # In first pass, skip start-last services; in second pass, only run them
        if [[ -z "$SERVICE_FILTER" ]]; then
            if [[ "$skip_start_last" == "skip" && -f "$dir/.start-last" ]]; then continue; fi
            if [[ "$skip_start_last" == "only" && ! -f "$dir/.start-last" ]]; then continue; fi
        fi
        echo "$label $service..."
        docker compose -f "$dir/docker-compose.yml" "$@"
        echo ""
    done
}

case "$ACTION" in
    --start)
        # Required by watchtower
        export DOCKER_API_VERSION
        DOCKER_API_VERSION=$(docker version --format '{{.Server.APIVersion}}')

        run_for_services "Starting" skip up -d
        run_for_services "Starting" only up -d

        wait_for_containers
        check_health
        ;;
    --stop)
        run_for_services "Stopping" "" down

        if [[ -z "$SERVICE_FILTER" ]]; then
            echo "All services stopped."
        else
            echo "$SERVICE_FILTER stopped."
        fi
        ;;
    --health)
        wait_for_containers
        check_health
        ;;
    --show-running)
        echo "Running containers:"
        echo ""

        while IFS= read -r name; do
            [[ -n "$name" ]] || continue

            local_service=$(docker inspect \
                --format '{{index .Config.Labels "homelab.service"}}' \
                "$name" 2>/dev/null)
            status=$(docker inspect \
                --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
                "$name" 2>/dev/null)

            case "$status" in
                healthy|running) symbol="✓" ;;
                unhealthy)       symbol="✗" ;;
                *)               symbol="?" ;;
            esac

            printf "  %s  %-40s %s\n" "$symbol" "${local_service:-$name}" "$status"
        done < <(docker ps \
            --filter "label=homelab.service" \
            --format "{{.Names}}" 2>/dev/null)
        ;;
    --setup)
        for dir in "$SERVICES_DIR"/*/; do
            [[ -f "$dir/setup.sh" ]] || continue
            service="$(basename "$dir")"
            [[ -z "$SERVICE_FILTER" || "$service" == "$SERVICE_FILTER" ]] || continue
            bash "$dir/setup.sh"
        done
        ;;
    --show-services)
        echo "Docker services:"
        for dir in "$SERVICES_DIR"/*/; do
            [[ -f "$dir/docker-compose.yml" ]] || continue
            echo "  $(basename "$dir")"
        done
        echo ""
        echo "Setup-only services:"
        for dir in "$SERVICES_DIR"/*/; do
            [[ -f "$dir/docker-compose.yml" ]] && continue
            [[ -f "$dir/setup.sh" ]] || continue
            echo "  $(basename "$dir")"
        done
        ;;
    --help)
        usage
        ;;
esac
