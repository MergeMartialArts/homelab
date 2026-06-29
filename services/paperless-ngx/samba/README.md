# Samba — Scanner Integration

Exposes the Paperless consume directory as a network share so scanners can drop documents directly into Paperless.

## Document Flow

```
Scanner → \\SERVER\paperless-scanner → PAPERLESS_DIR/consume → Paperless consumer → OCR → storage
```

## Shares

| Variable | Default | Path | Access |
|---|---|---|---|
| `SCANNER_SHARE_NAME` | `paperless-scanner` | `PAPERLESS_DIR/consume` | read/write |
| `PAPERLESS_SHARE_NAME` | `paperless` | `PAPERLESS_DIR` | read-only |

Share names are configurable in `.env`. Only `consume` is writable. Paperless manages everything else internally — modifying `media/` or `data/` directly can break document references and metadata.

## Setup

### Via Paperless setup (recommended)

Samba setup is offered as an optional step at the end of Paperless setup:

```bash
bash ../setup.sh
```

### Standalone

```bash
sudo bash setup.sh
```

Requirements:
- Debian / Ubuntu host
- `sudo` access
- `paperless-ngx/.env` present and configured (for `USERMAP_UID` / `PAPERLESS_DIR`)

What setup does:

1. Creates `.env` from `.env.example` if missing
2. Installs Samba packages
3. Creates Paperless data directories (`consume`, `media`, `data`, `export`) — safe to run even if `paperless-ngx/setup.sh` already created them
4. Sets ownership and permissions aligned with `USERMAP_UID` / `USERMAP_GID`
5. Creates a Samba user account
6. Installs Samba configuration
7. Enables and starts `smbd`

## Configuration

`.env` is created automatically from `.env.example` on first run.

| Variable | Default | Description |
|---|---|---|
| `WORKGROUP` | `WORKGROUP` | Samba workgroup name |
| `SHARE_USER` | derived from `USERMAP_UID` | Linux user for the share (override only if needed) |
| `PAPERLESS_DIR` | from `paperless-ngx/.env` | Paperless data directory (override only when running standalone) |

## User and Permission Alignment

`USERMAP_UID` and `USERMAP_GID` from `paperless-ngx/.env` are the single source of truth. They control:

- Which user Docker runs the Paperless container as
- Who owns the data directories on the host
- Which Linux user owns the Samba share

`SHARE_USER` is resolved automatically via `getent passwd $USERMAP_UID`. If the resolved user's UID/GID does not match `USERMAP_UID`/`USERMAP_GID`, setup exits with an error.

When running standalone without `paperless-ngx/.env`, UID/GID are derived from `$SUDO_USER`.

## Connecting

After setup the scanner share is available at:

```
\\SERVER_IP\SCANNER_SHARE_NAME
```

The actual share name and server IP are printed at the end of setup. Login with the Linux username and the Samba password set during setup.

### Recommended Scanner Settings

| Setting | Value |
|---|---|
| Format | PDF |
| OCR | Disabled — Paperless handles OCR |
| Duplex | As needed |

## Troubleshooting

```bash
# Service status
systemctl status smbd

# List shares
smbclient -L localhost -U USERNAME

# Check permissions on consume directory
ls -la /srv/paperless/consume

# Live logs
journalctl -u smbd -f
```
