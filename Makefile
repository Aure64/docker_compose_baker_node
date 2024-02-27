# Inclure les variables d'environnement depuis le fichier .env
include .env
export

# Définition des variables pour faciliter les modifications
DOCKER_COMPOSE_TEZOS = docker compose -f docker-compose/tezos.yml
DOCKER_COMPOSE_MONITORING = docker compose -f docker-compose/monitoring.yml
NETWORK_NAME = app_network

# URL de la snapshot varie selon le réseau et le mode
SNAPSHOT_BASE_URL = https://snapshots.eu.tzinit.org
SNAPSHOT_FILE = ./data/snapshot.rolling

ifeq ($(NETWORK),weeklynet)
MODE = rolling
endif

# Construction de l'URL de la snapshot en fonction du réseau et du mode
SNAPSHOT_URL = $(SNAPSHOT_BASE_URL)/$(NETWORK)/$(MODE)

# Cible par défaut
all: network launch-node clean-node-data download-snapshot import-snapshot launch-node-after-import monitoring

# Créer le réseau Docker s'il n'existe pas déjà
network:
	@docker network ls | grep $(NETWORK_NAME) || docker network create $(NETWORK_NAME)

# Lancer le conteneur du nœud Tezos
launch-node:
	$(DOCKER_COMPOSE_TEZOS) up -d node

# Nettoyer les données du nœud
clean-node-data:
	$(DOCKER_COMPOSE_TEZOS) stop node
	@rm -rf ./data/node_data/data/daily_logs ./data/node_data/data/lock ./data/node_data/data/store ./data/node_data/data/context

# Télécharger la dernière snapshot
download-snapshot:
	@echo "Téléchargement de la snapshot depuis $(SNAPSHOT_URL)"
	@wget -O $(SNAPSHOT_FILE) $(SNAPSHOT_URL)

# Importer la snapshot
import-snapshot:
	$(DOCKER_COMPOSE_TEZOS) up import

# Relancer le nœud après l'importation
launch-node-after-import:
	$(DOCKER_COMPOSE_TEZOS) up -d node

# Lancer les services de monitoring
monitoring:
	$(DOCKER_COMPOSE_MONITORING) up -d

# Arrêter et nettoyer les ressources
stop:
	@$(DOCKER_COMPOSE_TEZOS) down
	@$(DOCKER_COMPOSE_MONITORING) down
	@docker network rm $(NETWORK_NAME) || true
	@echo "Toutes les ressources ont été nettoyées."

# Nettoyer les volumes Docker et les images (facultatif)
clean-docker:
	@docker volume prune -f
	@docker image prune -f
	
clean-volumes:
	docker volume rm docker-compose_grafana-storage docker-compose_loki-data docker-compose_netdatacache docker-compose_netdataconfig docker-compose_netdatalib || true

