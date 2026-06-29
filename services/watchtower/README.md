# Watchtower

Monitors Docker containers for image updates and sends email notifications.

Runs in monitor-only mode: it detects new images and reports them but does not automatically update or restart containers.

## Setup

Run once before starting:

```bash
bash setup.sh
```

What setup does:

1. Creates `.env` from `.env.example` if missing
2. Pulls the Watchtower image

### Configuration

Edit `.env` after setup. No values are required — all have sensible defaults.

| Variable | Default | Description |
|---|---|---|
| `WATCHTOWER_SCHEDULE` | `0 0 6 * * *` | When to check for updates (daily at 6am) |
| `WATCHTOWER_MONITOR_ONLY` | `true` | Notify only, never update containers |
| `WATCHTOWER_NOTIFICATION_URL` | — | Set to enable notifications (shoutrrr URL, e.g. `smtp://...`) |
| `WATCHTOWER_LOG_LEVEL` | `info` | Log verbosity |

## Start

```bash
DOCKER_API_VERSION=$(docker version --format '{{.Server.APIVersion}}') \
  docker compose up -d
```

Or via services.sh (handles `DOCKER_API_VERSION` automatically):

```bash
../services.sh --start --watchtower
```

## Stop

```bash
docker compose down
```

## Logs

```bash
docker compose logs -f
```
