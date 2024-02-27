.PHONY: all create-network launch-node clean-node-data download-snapshot import-snapshot launch-node-after-import launch-monitoring stop clean-volumes clean-images clean-docker

# Docker network name
NETWORK_NAME=app_network

# Include environment variables from the .env file
include .env
export

# Dynamically build the snapshot URL based on TEZOS_NETWORK and TEZOS_HISTORY_MODE environment variables
SNAPSHOT_BASE_URL=https://snapshots.eu.tzinit.org
SNAPSHOT_URL=$(SNAPSHOT_BASE_URL)/$(TEZOS_NETWORK)/$(TEZOS_HISTORY_MODE)
SNAPSHOT_FILE=./data/snapshot.rolling

# Define variables for docker-compose commands to simplify modifications
DOCKER_COMPOSE_TEZOS=docker compose -f docker-compose/tezos.yml
DOCKER_COMPOSE_MONITORING=docker compose -f docker-compose/monitoring.yml

# Default target to run the whole setup process
all: create-network launch-node clean-node-data download-snapshot import-snapshot launch-node-after-import launch-monitoring

# Create the Docker network if it doesn't already exist
create-network:
	@docker network ls | grep -q $(NETWORK_NAME) || docker network create $(NETWORK_NAME)

# Launch the Tezos node container
launch-node:
	$(DOCKER_COMPOSE_TEZOS) up -d node

# Clean node data
clean-node-data:
	$(DOCKER_COMPOSE_TEZOS) stop node
	@sudo rm -rf ./data/node_data/data/daily_logs ./data/node_data/data/lock ./data/node_data/data/store ./data/node_data/data/context

# Download the latest snapshot
download-snapshot:
	@echo "Downloading snapshot from $(SNAPSHOT_URL)"
	@wget -O $(SNAPSHOT_FILE) $(SNAPSHOT_URL)

# Import the snapshot
import-snapshot:
	$(DOCKER_COMPOSE_TEZOS) up import
	@echo "Removing the snapshot file to save space."
	@rm -f $(SNAPSHOT_FILE)
	
# Relaunch the node after importing the snapshot
launch-node-after-import:
	$(DOCKER_COMPOSE_TEZOS) up -d node

# Launch monitoring services
launch-monitoring:
	$(DOCKER_COMPOSE_MONITORING) up -d

# Stop and clean up resources
stop:
	@$(DOCKER_COMPOSE_TEZOS) down
	@$(DOCKER_COMPOSE_MONITORING) down
	@docker network rm $(NETWORK_NAME) || true
	@echo "All resources have been cleaned up."

# Clean Docker volumes and images (optional)
clean-docker:
	@docker volume prune -f
	@docker image prune -a -f

clean-volumes:
	@docker volume rm $(shell docker volume ls -q --filter name=docker-compose_) || true
