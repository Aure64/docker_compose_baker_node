.PHONY: create-network launch-node clean-node-data download-snapshot import-snapshot restart-node launch-monitoring stop clean-volumes clean-images clean-all

# Nom du réseau Docker
NETWORK_NAME=app_network

# Lire les variables d'environnement
-include .env
export

# Construire l'URL du snapshot en fonction des variables TEZOS_NETWORK et TEZOS_HISTORY_MODE
SNAPSHOT_BASE_URL=https://snapshots.eu.tzinit.org
SNAPSHOT_URL=$(SNAPSHOT_BASE_URL)/$(TEZOS_NETWORK)/$(TEZOS_HISTORY_MODE)

# Créer le réseau Docker s'il n'existe pas
create-network:
	@docker network ls | grep -q $(NETWORK_NAME) || docker network create $(NETWORK_NAME)

# Lancer le conteneur du noeud Tezos
launch-node:
	docker compose -f docker-compose/tezos.yml up -d node

# Nettoyer les données du nœud
clean-node-data:
	docker compose -f docker-compose/tezos.yml stop node
	sudo rm -rf ./data/node_data/data/daily_logs ./data/node_data/data/lock ./data/node_data/data/store ./data/node_data/data/context

# Télécharger la dernière snapshot
download-snapshot:
	wget -O ./data/snapshot.rolling $(SNAPSHOT_URL)

# Importer la snapshot dans le volume du nœud Tezos
import-snapshot: download-snapshot
	docker compose -f docker-compose/tezos.yml up import

# Redémarrer le nœud Tezos après importation
restart-node:
	docker compose -f docker-compose/tezos.yml up -d node

# Lancer les services de monitoring
launch-monitoring:
	docker compose -f docker-compose/monitoring.yml up -d

# Arrêter tous les conteneurs
stop:
	docker compose -f docker-compose/tezos.yml down
	docker compose -f docker-compose/monitoring.yml down

clean-volumes:
	docker volume rm docker-compose_grafana-storage docker-compose_loki-data docker-compose_netdatacache docker-compose_netdataconfig docker-compose_netdatalib || true
	
# Nettoyer toutes les images Docker non utilisées
clean-images:
	docker image prune -a -f


	

# Nettoyer tout : conteneurs, volumes et images
clean-all: stop clean-volumes clean-images
	@echo "Nettoyage complet effectué."

# Cible par défaut pour lancer l'ensemble du processus
all: create-network launch-node clean-node-data import-snapshot restart-node launch-monitoring