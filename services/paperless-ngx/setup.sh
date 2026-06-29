#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"


########################################
# Checks
########################################

if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this script as root."
    exit 1
fi

check_docker
ensure_env "$SCRIPT_DIR"

# Populate USERMAP_UID/GID from the running user if still empty
sed -i \
    -e "s|^USERMAP_UID=$|USERMAP_UID=$(id -u)|" \
    -e "s|^USERMAP_GID=$|USERMAP_GID=$(id -g)|" \
    "$SCRIPT_DIR/.env"

validate_env "$SCRIPT_DIR"

set -a
# shellcheck source=/dev/null
source "$SCRIPT_DIR/.env"
set +a


########################################
# Directories
########################################

PAPERLESS_DIR="${PAPERLESS_DIR:-/srv/paperless}"

echo "Creating Paperless data directories at $PAPERLESS_DIR..."

if ! mkdir -p \
    "$PAPERLESS_DIR/consume" \
    "$PAPERLESS_DIR/media" \
    "$PAPERLESS_DIR/data" \
    "$PAPERLESS_DIR/export" 2>/dev/null; then

    echo "Creating directories requires elevated permissions..."
    sudo mkdir -p \
        "$PAPERLESS_DIR/consume" \
        "$PAPERLESS_DIR/media" \
        "$PAPERLESS_DIR/data" \
        "$PAPERLESS_DIR/export"
fi

sudo chown -R "$USERMAP_UID:$USERMAP_GID" "$PAPERLESS_DIR"
sudo chmod -R u=rwX,g=rwX,o=rX "$PAPERLESS_DIR"

echo "Directories ready."
echo ""


########################################
# Images
########################################

echo "Pulling images..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" pull
echo ""

echo "Building webserver image..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" build
echo ""


########################################
# Samba (optional)
########################################

echo "Set up Samba for scanner integration? [y/N] "
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    if ! sudo PAPERLESS_DIR="$PAPERLESS_DIR" bash "$SCRIPT_DIR/samba/setup.sh"; then
        echo ""
        echo "Samba setup incomplete. Edit $SCRIPT_DIR/samba/.env then run:"
        echo "  sudo bash $SCRIPT_DIR/samba/setup.sh"
    fi
fi
echo ""


########################################
# Done
########################################

echo "================================="
echo "paperless-ngx setup complete"
echo "================================="
echo ""
echo "Next steps:"
echo "  1. Start:"
echo "       docker compose -f $SCRIPT_DIR/docker-compose.yml up -d"
echo "     or via services.sh:"
echo "       $SCRIPT_DIR/../services.sh --start --paperless-ngx"
echo ""
echo "  3. Access: ${PAPERLESS_URL:-http://localhost:8000}"
echo ""
