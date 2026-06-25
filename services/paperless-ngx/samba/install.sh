#!/usr/bin/env bash

set -euo pipefail

########################################
# Configuration
########################################

# Use the real user who called sudo, not root
SHARE_USER="${SUDO_USER:-$USER}"

PAPERLESS_DIR="/srv/paperless"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SMB_CONFIG="/etc/samba/smb.conf"



########################################
# Checks
########################################

if [[ $EUID -ne 0 ]]; then
    echo "Run this script with sudo."
    exit 1
fi

if ! id "$SHARE_USER" >/dev/null 2>&1; then
    echo "ERROR: Linux user '$SHARE_USER' does not exist."
    exit 1
fi

echo "Using user: $SHARE_USER"
echo "Paperless directory: $PAPERLESS_DIR"



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
# Create directories
########################################

echo "Creating Paperless directories..."

mkdir -p \
    "$PAPERLESS_DIR/consume" \
    "$PAPERLESS_DIR/media" \
    "$PAPERLESS_DIR/data" \
    "$PAPERLESS_DIR/export"



########################################
# Permissions
########################################

echo "Setting permissions..."

chown -R \
    "$SHARE_USER:$SHARE_USER" \
    "$PAPERLESS_DIR"

chmod -R u=rwX,g=rwX,o=rX \
    "$PAPERLESS_DIR"



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

if [[ -f "$SMB_CONFIG" ]]; then
    cp "$SMB_CONFIG" "${SMB_CONFIG}.backup.$(date +%F-%H%M)"
fi

sed \
    "s/%USERNAME%/$SHARE_USER/g" \
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
# Output
########################################

SERVER_IP=$(hostname -I | awk '{print $1}')

echo
echo "================================="
echo "Samba installation complete"
echo "================================="
echo

echo "Scanner share:"
echo "\\\\${SERVER_IP}\\paperless-scanner"

echo

echo "Paperless share:"
echo "\\\\${SERVER_IP}\\paperless"

echo

echo "User:"
echo "$SHARE_USER"

echo
