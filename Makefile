.PHONY: all create-network pull-images find-ports setup-grafana-dashboard launch-node clean-node-data download-snapshot import-snapshot launch-node-after-import launch-monitoring stop clean-docker

# Docker network name
NETWORK_NAME=app_network

# Include environment variables from the .env file
include .env
export

# Define variables for docker-compose commands to simplify modifications
DOCKER_COMPOSE_TEZOS=docker compose -f docker-compose/tezos.yml 
DOCKER_COMPOSE_MONITORING=docker compose -f docker-compose/monitoring.yml 

# Default target to run the whole setup process
all: create-network pull-images find-ports setup-grafana-dashboard launch-node clean-node-data download-snapshot import-snapshot launch-node-after-import launch-monitoring

# Create the Docker network if it doesn't already exist
create-network:
	@docker network ls | grep -q $(NETWORK_NAME) || docker network create $(NETWORK_NAME)

# Pull the latest Docker images
pull-images:
	@docker pull tezos/tezos:latest
	@docker pull tezos/tezos-bare:master

# Find available ports starting from 8732
find-ports:
	@start_port=8732; \
	end_port=8734; \
	current_port=$$start_port; \
	while [ $$current_port -le $$end_port ]; do \
		if ! lsof -i :$$current_port >/dev/null; then \
			echo $$current_port > .port_$(NODE_NAME); \
			exit 0; \
		fi; \
		current_port=$$((current_port+1)); \
	done; \
	echo "No available ports found in range $$start_port-$$end_port" >&2; \
	exit 1

# Setup Grafana dashboard
setup-grafana-dashboard:
	@cp ./data/grafana/provisioning/dashboards/${TEZOS_NETWORK}/${TEZOS_NETWORK}.json ./data/grafana/provisioning/dashboards/dashboard.json

# Launch the Tezos node container
launch-node:
	@PORT=$(shell cat .port_$(NODE_NAME)) NODE_NAME=$(NODE_NAME) $(DOCKER_COMPOSE_TEZOS) up -d node

# Clean node data
clean-node-data:
	@PORT=$(shell cat .port_$(NODE_NAME)) NODE_NAME=$(NODE_NAME) $(DOCKER_COMPOSE_TEZOS) stop node
	@sudo rm -rf ./data/node_data_$(NODE_NAME)/data/daily_logs ./data/node_data_$(NODE_NAME)/data/lock ./data/node_data_$(NODE_NAME)/data/store ./data/node_data_$(NODE_NAME)/data/context

# Download the latest snapshot
download-snapshot:
	@echo "Downloading snapshot from $(SNAPSHOT_URL)"
	@wget -O $(SNAPSHOT_FILE) $(SNAPSHOT_URL)

# Clean data directory before importing the snapshot
clean-data-dir:
	@sudo rm -rf ./data/node_data_$(NODE_NAME)/data/lock ./data/node_data_$(NODE_NAME)/data/context ./data/node_data_$(NODE_NAME)/data/daily_logs ./data/node_data_$(NODE_NAME)/data/store ./data/node_data_$(NODE_NAME)/data/protocol

# Import the snapshot
import-snapshot: clean-data-dir
	@PORT=$(shell cat .port_$(NODE_NAME)) NODE_NAME=$(NODE_NAME) $(DOCKER_COMPOSE_TEZOS) up import
	@echo "Removing the snapshot file to save space."
	@rm -f $(SNAPSHOT_FILE)

# Relaunch the node after importing the snapshot
launch-node-after-import:
	@PORT=$(shell cat .port_$(NODE_NAME)) NODE_NAME=$(NODE_NAME) $(DOCKER_COMPOSE_TEZOS) up -d node

# Launch monitoring services
launch-monitoring:
	@docker ps | grep -q grafana || $(DOCKER_COMPOSE_MONITORING) up -d

# Stop and clean up resources
stop:
	@PORT=$(shell cat .port_$(NODE_NAME)) NODE_NAME=$(NODE_NAME) $(DOCKER_COMPOSE_TEZOS) down
	@$(DOCKER_COMPOSE_MONITORING) down
	@docker network rm $(NETWORK_NAME) || true
	@echo "All resources have been cleaned up."

# Clean Docker volumes and images (optional)
clean-docker:
	@docker volume prune -f
	@docker image prune -a -f

clean-volumes:
	@docker volume rm $(shell docker volume ls -q --filter name=docker-compose_) || true
