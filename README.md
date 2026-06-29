# Homelab

Self-hosted services managed with Docker Compose.

## Services

| Service | Description |
|---|---|
| [paperless-ngx](services/paperless-ngx/) | Document management with OCR and full-text search |
| [watchtower](services/watchtower/) | Container update monitoring and notifications |
| [homelab-api](services/homelab-api/) | HTTP API to manage services (start, stop, setup, health) |
| [homelab-frontend](services/homelab-frontend/) | Web UI for the homelab API |

## Structure

```
homelab/
└── services/
    ├── services.sh              # Manage all services
    ├── lib.sh                   # Shared setup helpers
    ├── paperless-ngx/
    │   ├── setup.sh             # First-time setup
    │   ├── docker-compose.yml
    │   ├── .env.example
    │   └── samba/               # Optional scanner share
    │       ├── setup.sh
    │       └── .env.example
    ├── watchtower/
    │   ├── setup.sh
    │   ├── docker-compose.yml
    │   └── .env.example
    ├── homelab-api/
    │   ├── setup.sh
    │   ├── docker-compose.yml
    │   └── .env.example
    └── homelab-frontend/
        ├── setup.sh
        ├── docker-compose.yml
        └── .env.example
```

## Usage

All services are managed through `services.sh`:

```bash
cd services

./services.sh --setup --all        # First-time setup for all services
./services.sh --start              # Start all services
./services.sh --stop               # Stop all services
./services.sh --health             # Health check
./services.sh --show-running       # Show running containers
./services.sh --show-services      # List available services
```

A single service can be targeted by appending its name:

```bash
./services.sh --setup --paperless-ngx
./services.sh --start --watchtower
./services.sh --stop  --paperless-ngx
```

`homelab-api` and `homelab-frontend` are excluded from `--start`/`--stop` without a target — start them explicitly:

```bash
./services.sh --start --homelab-api
./services.sh --start --homelab-frontend
```

## Requirements

- Docker with Compose v2
- User in the `docker` group
- Debian / Ubuntu (required for Samba)
