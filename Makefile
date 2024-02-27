.PHONY: create-network launch-node clean-node-data download-snapshot import-snapshot restart-node launch-monitoring clean-volumes clean-images clean-all

# Nom du réseau Docker
NETWORK_NAME=app_network
# URL de la snapshot
SNAPSHOT_URL=https://snapshots.eu.tzinit.org/ghostnet/rolling
# Chemin local de la snapshot
SNAPSHOT_FILE=./data/snapshot.rolling

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
	wget -O $(SNAPSHOT_FILE) $(SNAPSHOT_URL)

# Importer la snapshot dans le volume du nœud Tezos
import-snapshot: download-snapshot
	docker compose -f docker-compose/tezos.yml up import

# Redémarrer le nœud Tezos après importation
restart-node:
	docker compose -f docker-compose/tezos.yml up -d node

# Lancer les services de monitoring
launch-monitoring:
	docker compose -f docker-compose/monitoring.yml up -d

# Nettoyer tous les volumes Docker non utilisés
clean-volumes:
	docker volume prune -f

# Nettoyer toutes les images Docker non utilisées
clean-images:
	docker image prune -a -f

# Nettoyer tout : conteneurs, volumes et images
clean-all: clean-node-data clean-volumes clean-images
	@echo "Nettoyage complet effectué."

# Cible par défaut pour lancer l'ensemble du processus
all: create-network launch-node clean-node-data import-snapshot restart-node launch-monitoring

