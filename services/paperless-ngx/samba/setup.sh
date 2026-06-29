#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib.sh
source "$SCRIPT_DIR/../../lib.sh"


########################################
# Checks
########################################

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

ensure_env "$SCRIPT_DIR"
validate_env "$SCRIPT_DIR"

# Load paperless-ngx .env first as baseline (USERMAP_UID, USERMAP_GID, PAPERLESS_DIR)
if [[ -f "$SERVICES_DIR/paperless-ngx/.env" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$SERVICES_DIR/paperless-ngx/.env"
    set +a
fi

# Load samba config — can override paperless values
set -a
# shellcheck source=/dev/null
source "$SCRIPT_DIR/.env"
set +a

PAPERLESS_DIR="${PAPERLESS_DIR:-/srv/paperless}"
WORKGROUP="${WORKGROUP:-WORKGROUP}"
SCANNER_SHARE_NAME="${SCANNER_SHARE_NAME:-paperless-scanner}"
PAPERLESS_SHARE_NAME="${PAPERLESS_SHARE_NAME:-paperless}"
# Fall back to the invoking user's UID/GID if not set by paperless-ngx/.env
USERMAP_UID="${USERMAP_UID:-$(id -u "${SUDO_USER:-$USER}")}"
USERMAP_GID="${USERMAP_GID:-$(id -g "${SUDO_USER:-$USER}")}"

# Derive SHARE_USER from USERMAP_UID if not explicitly overridden in samba/.env
SHARE_USER="${SHARE_USER:-$(getent passwd "$USERMAP_UID" | cut -d: -f1)}"

if [[ -z "$SHARE_USER" ]]; then
    echo "ERROR: Cannot resolve a username for UID $USERMAP_UID."
    echo "Set SHARE_USER explicitly in $SCRIPT_DIR/.env or update USERMAP_UID in paperless-ngx/.env."
    exit 1
fi

if ! id "$SHARE_USER" >/dev/null 2>&1; then
    echo "ERROR: Linux user '$SHARE_USER' does not exist."
    exit 1
fi

# Validate that SHARE_USER's UID/GID matches what paperless expects
actual_uid=$(id -u "$SHARE_USER")
actual_gid=$(id -g "$SHARE_USER")

if [[ "$actual_uid" != "$USERMAP_UID" || "$actual_gid" != "$USERMAP_GID" ]]; then
    echo "ERROR: User '$SHARE_USER' has UID=$actual_uid GID=$actual_gid"
    echo "       but paperless-ngx expects USERMAP_UID=$USERMAP_UID USERMAP_GID=$USERMAP_GID"
    echo "Fix USERMAP_UID/GID in paperless-ngx/.env or set SHARE_USER in samba/.env."
    exit 1
fi

echo "Using user: $SHARE_USER (UID=$USERMAP_UID GID=$USERMAP_GID)"
echo "Paperless directory: $PAPERLESS_DIR"
echo ""


########################################
# Install Samba
########################################

echo "Installing Samba..."

apt update

apt install -y \
    samba \
    samba-common-bin \
    smbclient


########################################
# Directories and permissions
########################################

echo "Creating Paperless data directories at $PAPERLESS_DIR..."

mkdir -p \
    "$PAPERLESS_DIR/consume" \
    "$PAPERLESS_DIR/media" \
    "$PAPERLESS_DIR/data" \
    "$PAPERLESS_DIR/export"

chown -R "$USERMAP_UID:$USERMAP_GID" "$PAPERLESS_DIR"
chmod -R u=rwX,g=rwX,o=rX "$PAPERLESS_DIR"

echo "Directories ready."
echo ""


########################################
# Samba user
########################################

echo "Creating Samba account..."

if pdbedit -u "$SHARE_USER" >/dev/null 2>&1; then
    echo "Samba user exists: $SHARE_USER"
else
    smbpasswd -a "$SHARE_USER"
fi


########################################
# Samba config
########################################

if [[ ! -f "$SCRIPT_DIR/smb.conf.template" ]]; then
    echo "ERROR: smb.conf.template missing"
    exit 1
fi

echo "Installing Samba configuration..."

SMB_CONFIG="/etc/samba/smb.conf"

if [[ -f "$SMB_CONFIG" ]]; then
    cp "$SMB_CONFIG" "${SMB_CONFIG}.backup.$(date +%F-%H%M)"
fi

sed \
    -e "s|%USERNAME%|$SHARE_USER|g" \
    -e "s|%PAPERLESS_DIR%|$PAPERLESS_DIR|g" \
    -e "s|%WORKGROUP%|$WORKGROUP|g" \
    -e "s|%SCANNER_SHARE_NAME%|$SCANNER_SHARE_NAME|g" \
    -e "s|%PAPERLESS_SHARE_NAME%|$PAPERLESS_SHARE_NAME|g" \
    "$SCRIPT_DIR/smb.conf.template" \
    > "$SMB_CONFIG"


########################################
# Validate
########################################

echo "Testing Samba configuration..."

testparm


########################################
# Restart
########################################

echo "Starting Samba..."

systemctl enable smbd
systemctl restart smbd


########################################
# Done
########################################

SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================="
echo "Samba setup complete"
echo "================================="
echo ""
echo "Scanner share (read/write):"
echo "  \\\\${SERVER_IP}\\${SCANNER_SHARE_NAME}"
echo ""
echo "Paperless share (read-only):"
echo "  \\\\${SERVER_IP}\\${PAPERLESS_SHARE_NAME}"
echo ""
echo "User: $SHARE_USER"
echo ""
