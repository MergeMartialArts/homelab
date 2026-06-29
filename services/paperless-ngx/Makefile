COMPOSE = docker compose -f docker-compose.yml

update-redis:
	$(COMPOSE) pull broker
	$(COMPOSE) up -d broker

update-postgres:
	$(COMPOSE) pull db
	$(COMPOSE) up -d db

update-gotenberg:
	$(COMPOSE) pull gotenberg
	$(COMPOSE) up -d gotenberg

update-tika:
	$(COMPOSE) pull tika
	$(COMPOSE) up -d tika

build-webserver:
	$(COMPOSE) build webserver
	$(COMPOSE) up -d webserver

update-all: update-redis update-postgres update-gotenberg update-tika build-webserver
