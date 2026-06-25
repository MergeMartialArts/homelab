# Samba Scanner Integration

Samba provides a network share for scanners to upload documents into Paperless-ngx.

The Samba service runs on the Linux host and exposes only the Paperless consume directory.

---

## Purpose

The document flow is:

```text
Scanner
   |
   v
Samba share
   |
   v
Paperless consume folder
   |
   v
Paperless-ngx consumer
   |
   +--> OCR
   +--> indexing
   +--> storage
```

The scanner never writes directly into Paperless storage.

---

## Why only expose consume?

Paperless manages its internal storage:

```
/srv/paperless/

├── consume/
│   └── incoming scanner files
│
├── media/
│   └── processed documents
│
├── data/
│   └── database and application data
│
└── export/
    └── exported documents
```

Only:

```
consume/
```

is shared through Samba.

The following directories must not be modified manually:

```
media/
data/
```

Changing them can break document references and metadata.

---

## Configuration

The Paperless storage location is defined in:

```
.env
```

Example:

```env
PAPERLESS_DIR=/srv/paperless
```

This value is used by:

- Docker Compose
- Samba installation

Both services point to the same storage location.

---

## Installation

Requirements:

- Debian / Ubuntu host
- sudo access
- network access from scanner
- Paperless storage directory configured


From this directory:

```bash
cd services/paperless-ngx/samba
```

Run:

```bash
sudo bash install.sh
```

The installer:

1. Installs Samba
2. Creates Paperless directories
3. Sets permissions
4. Creates Samba credentials
5. Installs Samba configuration
6. Starts the Samba service

---

## Scanner Configuration

After installation the share is available:

```
\\SERVER_IP\paperless-scanner
```

Example:

```
\\192.168.1.50\paperless-scanner
```

Login:

```
Username:
your Linux username

Password:
your Samba password
```

Set scanner destination:

```
paperless-scanner
```

Files will appear in:

```
PAPERLESS_DIR/consume
```

---

## Recommended Scanner Settings

Recommended:

- File format: PDF
- Quality: normal
- Duplex: enabled if needed
- OCR: disabled

Paperless performs OCR after import.

---

## Samba Compatibility Settings

The Samba configuration disables:

```ini
oplocks = no
level2 oplocks = no
strict sync = yes
```

Some scanners upload files slowly.

Without these settings Paperless may detect:

```
document.pdf
```

before the scanner has finished writing it.

Possible symptoms:

- invalid PDF
- corrupted document
- MIME detection errors

---

## Troubleshooting

Check Samba:

```bash
systemctl status smbd
```

---

List shares:

```bash
smbclient -L localhost -U USERNAME
```

---

Check permissions:

```bash
ls -la /srv/paperless/consume
```

---

View logs:

```bash
journalctl -u smbd
```

---

## Removing Samba

Stop Samba:

```bash
sudo systemctl disable smbd
sudo systemctl stop smbd
```

Remove package:

```bash
sudo apt remove samba
```

Paperless data remains:

```
PAPERLESS_DIR
```