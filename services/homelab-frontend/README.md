# Frontend

Single-page web app for managing homelab services. Provides buttons to start, stop, setup, and health-check services, with streaming terminal output in the browser.

Runs as a Docker service using a minimal FastAPI server that serves `index.html` and reverse-proxies all API calls to the [homelab API](../api/).

## Setup

Run once before starting:

```bash
bash setup.sh
```

What setup does:

1. Creates `.env` from `.env.example` if missing
2. Builds the Docker image

### Configuration

Edit `.env` after setup.

| Variable | Default | Description |
|---|---|---|
| `FRONTEND_PORT` | `8081` | Host port the UI is served on |
| `API_URL` | `http://host.docker.internal:8080` | URL of the homelab API (as seen from inside the container) |

The API must be running before you open the UI. See [../api/](../api/).

## Start

```bash
docker compose up -d
```

Or via services.sh:

```bash
../services.sh --start --homelab-frontend
```

Open: `http://localhost:8081`

## Stop

```bash
docker compose down
```

## Logs

```bash
docker compose logs -f
```

## Development

`index.html` is mounted as a volume — edit it and reload the browser without rebuilding. Changes to `serve.py` require a rebuild:

```bash
docker compose build && docker compose up -d
```
