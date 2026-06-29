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
validate_env "$SCRIPT_DIR"


########################################
# Build image
########################################

echo "Building frontend image..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" build
echo ""


########################################
# Done
########################################

echo "================================="
echo "Frontend setup complete"
echo "================================="
echo ""
echo "Start:"
echo "  docker compose -f $SCRIPT_DIR/docker-compose.yml up -d"
echo "  # or"
echo "  $(dirname "$SCRIPT_DIR")/services.sh --start --homelab-frontend"
echo ""
echo "Open:  http://localhost:${FRONTEND_PORT:-8081}"
echo ""
