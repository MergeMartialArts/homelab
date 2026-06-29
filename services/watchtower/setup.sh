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
# Image
########################################

export DOCKER_API_VERSION
DOCKER_API_VERSION=$(docker version --format '{{.Server.APIVersion}}')

echo "Pulling watchtower image..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" pull
echo ""


########################################
# Done
########################################

echo "================================="
echo "watchtower setup complete"
echo "================================="
echo ""
echo "Next step:"
echo "  Start:"
echo "       DOCKER_API_VERSION=$DOCKER_API_VERSION \\"
echo "         docker compose -f $SCRIPT_DIR/docker-compose.yml up -d"
echo "     or via services.sh:"
echo "       $SCRIPT_DIR/../services.sh --start --watchtower"
echo ""
