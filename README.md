# Homelab

Self-hosted services managed with Docker Compose and Linux services.

## Services

| Service | Technology | Purpose |
|---|---|---|
| Paperless-ngx | Docker Compose | Document management |
| Samba | Linux service | Scanner upload share |

## Structure

```text
homelab/
│
├── README.md
│
└── services/
    └── paperless-ngx/
        ├── docker-compose.yml
        ├── Dockerfile
        ├── paperless.env.example
        │
        ├── samba/
        │   ├── install.sh
        │   └── smb.conf.template
        │
        └── README.md
```

## Deployment

```bash
cd services/paperless-ngx

cp .paperless.env.example .paperless.env

docker compose up -d
```

## Infrastructure

| Component | Purpose |
|---|---|
| Docker Compose | Container deployment |
| PostgreSQL | Paperless database |
| Redis | Task queue |
| Apache Tika | Document parsing |
| Gotenberg | Office conversion |
| Samba | Scanner uploads |