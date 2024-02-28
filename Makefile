.PHONY: all create-network prepare-launch-node launch-node clean-node-data download-snapshot prepare-import-snapshot import-snapshot launch-node-after-import prepare-monitoring launch-monitoring stop clean-volumes clean-images clean-all

NETWORK_NAME := app_network

include .env
export

SNAPSHOT_BASE_URL := https://snapshots.eu.tzinit.org
SNAPSHOT_URL := $(SNAPSHOT_BASE_URL)/$(TEZOS_NETWORK)/$(TEZOS_HISTORY_MODE)
SNAPSHOT_FILE := ./data/snapshot.rolling

DOCKER_COMPOSE_TEZOS := docker compose -f docker-compose/tezos.yml
DOCKER_COMPOSE_MONITORING := docker compose -f docker-compose/monitoring.yml

all: create-network prepare-launch-node launch-node clean-node-data download-snapshot prepare-import-snapshot import-snapshot launch-node-after-import prepare-monitoring launch-monitoring

create-network:
	@echo "Creating Docker network $(NETWORK_NAME) if it does not exist..."
	@docker network ls | grep -q $(NETWORK_NAME) || docker network create $(NETWORK_NAME)

prepare-launch-node:
	@echo "Removing existing Tezos node container if it exists..."
	@docker ps -a | grep -q tezos-public-node && docker rm -f tezos-public-node || true

launch-node: prepare-launch-node
	@echo "Launching Tezos node..."
	$(DOCKER_COMPOSE_TEZOS) up -d node

clean-node-data:
	@echo "Cleaning Tezos node data..."
	$(DOCKER_COMPOSE_TEZOS) stop node
	@rm -rf ./data/node_data/data/daily_logs ./data/node_data/data/lock ./data/node_data/data/store ./data/node_data/data/context

download-snapshot:
	@echo "Downloading snapshot from $(SNAPSHOT_URL)..."
	@wget -O $(SNAPSHOT_FILE) $(SNAPSHOT_URL)

prepare-import-snapshot:
	@echo "Removing existing snapshot import container if it exists..."
	@docker ps -a | grep -q octez-snapshot-import && docker rm -f octez-snapshot-import || true

import-snapshot: prepare-import-snapshot
	@echo "Importing snapshot..."
	$(DOCKER_COMPOSE_TEZOS) up import
	@echo "Removing the snapshot file to save space."
	@rm -f $(SNAPSHOT_FILE)

launch-node-after-import:
	@echo "Relaunching Tezos node after import..."
	$(DOCKER_COMPOSE_TEZOS) up -d node

prepare-monitoring:
	@echo "Removing existing monitoring containers if they exist..."
	@docker ps -a | grep -q prometheus && docker rm -f prometheus || true
	@docker ps -a | grep -q grafana && docker rm -f grafana || true
	@docker ps -a | grep -q loki && docker rm -f loki || true
	@docker ps -a | grep -q promtail && docker rm -f promtail || true
	@docker ps -a | grep -q netdata && docker rm -f netdata || true

launch-monitoring: prepare-monitoring
	@echo "Launching monitoring services..."
	$(DOCKER_COMPOSE_MONITORING) up -d

stop:
	@echo "Stopping and removing all containers..."
	@$(DOCKER_COMPOSE_TEZOS) down
	@$(DOCKER_COMPOSE_MONITORING) down
	@docker network rm $(NETWORK_NAME) || true
	@echo "All containers stopped and network removed."

clean-volumes:
	@echo "Removing Docker volumes..."
	@docker volume prune -f

clean-images:
	@echo "Removing Docker images..."
	@docker image prune -a -f

clean-all: stop clean-volumes clean-images
	@echo "All Docker resources cleaned."
