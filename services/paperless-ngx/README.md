# Paperless-ngx

Document management with OCR, full-text search, and automatic filing.

## Components

| Container | Role |
|---|---|
| `webserver` | Paperless application |
| `db` | PostgreSQL database |
| `broker` | Redis task queue |
| `tika` | Document parsing (Office formats) |
| `gotenberg` | Document conversion |

## Setup

Run once before starting:

```bash
bash setup.sh
```

What setup does:

1. Creates `.env` from `.env.example` if missing
2. Fills in `USERMAP_UID` and `USERMAP_GID` from the user running the script
3. Creates data directories at `PAPERLESS_DIR`
4. Sets ownership and permissions on the data directories
5. Pulls and builds Docker images
6. Optionally runs [Samba setup](samba/README.md) for scanner integration

### Configuration

Edit `.env` before running setup. Required:

| Variable | Description |
|---|---|
| `PAPERLESS_SECRET_KEY` | Random secret — generate with `openssl rand -base64 32` |

Optional:

| Variable | Default | Description |
|---|---|---|
| `PAPERLESS_DIR` | `/srv/paperless` | Host path for data storage |
| `PAPERLESS_URL` | `http://localhost:8000` | Public URL |
| `PAPERLESS_TIME_ZONE` | `Europe/Berlin` | Timezone for scheduling |

## Start

```bash
docker compose up -d
```

Or via services.sh:

```bash
../services.sh --start --paperless-ngx
```

## Stop

```bash
docker compose down
```

## First Login

Create an admin user after the first start:

```bash
docker compose run --rm webserver createsuperuser
```

## Update

Update all containers at once:

```bash
docker compose pull
docker compose build
docker compose up -d
```

Or update individual containers via the `Makefile`:

```bash
make update-redis
make update-postgres
make update-gotenberg
make update-tika
make build-webserver
make update-all        # all of the above
```

## Logs

```bash
docker compose logs -f
```

## Scanner Integration

See [samba/README.md](samba/README.md).
