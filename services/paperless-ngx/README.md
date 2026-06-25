# Paperless-ngx

Document management service.

## Configuration

Create environment file:

```bash
cp .paperless.env.example .paperless.env
```

Edit values before starting.

Required values:

```env
PAPERLESS_DIR=/srv/paperless
POSTGRES_PASSWORD=change-me
PAPERLESS_SECRET_KEY=change-me
```

Generate secret:

```bash
openssl rand -base64 32
```

## Start

```bash
docker compose up -d
```

## Stop

```bash
docker compose down
```

## Update

```bash
docker compose pull
docker compose build
docker compose up -d
```

## Admin User

```bash
docker compose run --rm webserver createsuperuser
```

## Logs

```bash
docker compose logs -f
```

## Scanner Integration

Samba setup:

```text
samba/README.md
```