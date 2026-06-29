# API

FastAPI service that manages homelab services — start, stop, setup, and health-check via HTTP. Used by the [frontend](../frontend/) but also curl-friendly.

Runs as a Docker container with the Docker socket and the services directory mounted, so it can invoke `services.sh` and `docker compose` commands on the host.

## Setup

Run once before starting:

```bash
bash setup.sh
```

What setup does:

1. Creates `.env` from `.env.example` if missing
2. Auto-fills `HOST_SERVICES_DIR` with the current services directory path
3. Builds the Docker image

### Configuration

Edit `.env` after setup.

| Variable | Default | Description |
|---|---|---|
| `API_PORT` | `8080` | Host port the API listens on |
| `HOST_SERVICES_DIR` | *(auto-filled)* | Absolute path to `services/` on the host — must match the actual host path |

`HOST_SERVICES_DIR` is critical: the API container mounts this directory at the same path so that `docker compose` commands resolve volume paths correctly against the host filesystem.

## Start

```bash
docker compose up -d
```

Or via services.sh:

```bash
../services.sh --start --homelab-api
```

## Stop

```bash
docker compose down
```

## Logs

```bash
docker compose logs -f
```

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/services` | List available services |
| `POST` | `/services/{name}/start` | Start a service (streams output) |
| `POST` | `/services/{name}/stop` | Stop a service (streams output) |
| `POST` | `/services/{name}/setup` | Run a service's setup.sh (streams output) |
| `GET` | `/health` | Health check across all running services (streams output) |

All streaming endpoints return `text/plain` and end with `[exit 0: ok]` or `[exit N: error]`.

## Notes

- Setup scripts that require `sudo` (e.g. samba) cannot run through the API — run them directly on the host.
- The API container needs access to the Docker socket (`/var/run/docker.sock`).
