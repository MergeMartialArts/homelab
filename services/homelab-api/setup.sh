#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"


########################################
# Checks
########################################

check_docker
ensure_env "$SCRIPT_DIR"

# Auto-fill HOST_SERVICES_DIR with the actual host path
sed -i "s|^HOST_SERVICES_DIR=$|HOST_SERVICES_DIR=$SERVICES_DIR|" "$SCRIPT_DIR/.env"

validate_env "$SCRIPT_DIR"


########################################
# Build image
########################################

echo "Building API image..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" build
echo ""


########################################
# Done
########################################

echo "================================="
echo "API setup complete"
echo "================================="
echo ""
echo "Start:"
echo "  docker compose -f $SCRIPT_DIR/docker-compose.yml up -d"
echo "  # or"
echo "  $SERVICES_DIR/services.sh --start --homelab-api"
echo ""
echo "Endpoints:"
echo "  GET  /services"
echo "  POST /services/{name}/setup"
echo "  POST /services/{name}/start"
echo "  POST /services/{name}/stop"
echo "  GET  /health"
echo ""
