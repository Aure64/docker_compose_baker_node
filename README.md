
# README pour le Projet Docker Compose Tezos

Ce README guide à travers les étapes nécessaires pour configurer et lancer un nœud Tezos, importer une snapshot blockchain, et configurer le monitoring avec Prometheus, Grafana, et Netdata.

## Prérequis

- Docker et Docker Compose installés sur votre machine.
- Accès à une ligne de commande/terminal.

## Configuration et Lancement

### Étape 1: Lancer le Réseau `app_network`

Créez un réseau Docker qui sera utilisé par tous les conteneurs de ce projet.

```
docker network create app_network
```

### Étape 2: Lancer le Conteneur du Noeud dans Docker Compose Tezos

Démarrez le conteneur du nœud Tezos en utilisant le fichier Docker Compose préparé pour Tezos.

```
docker compose -f docker-compose/tezos.yml up -d node
```

### Étape 3: Stopper le Conteneur et Nettoyer le Dossier `node_data`

Arrêtez le conteneur du nœud Tezos, puis nettoyez les données obsolètes avant d'importer la snapshot.

```
docker compose -f docker-compose/tezos.yml stop node
sudo rm -rf ./data/node_data/data/daily_logs ./data/node_data/data/lock ./data/node_data/data/store ./data/node_data/data/context

```

### Étape 4: Télécharger la Snapshot

Téléchargez la dernière snapshot de la blockchain Tezos pour Ghostnet.

```
wget -O data/snapshot.rolling https://snapshots.tezos.org/ghostnet/rolling
```

### Étape 5: Lancer le Conteneur d'Import

Démarrez le processus d'importation de la snapshot dans le volume du nœud Tezos.

```
docker compose -f docker-compose/tezos.yml up -d import
```

### Étape 6: Lancer le Conteneur du Noeud Après l'Importation

Une fois l'importation terminée (cela peut prendre un certain temps), relancez le conteneur du nœud Tezos.

```
docker compose -f docker-compose/tezos.yml up -d node
```

### Étape 7: Lancer le Docker Compose Monitoring

Démarrez les services de monitoring (Prometheus, Grafana, et Netdata).

```
docker compose -f docker-compose/monitoring.yml up -d
```

### Étape 8: Tester l'Accès aux Interfaces Web

- **Netdata**: Accédez à Netdata pour voir les statistiques en temps réel de votre nœud.
    - URL: http://localhost:19999/
- **Grafana**: Ouvrez Grafana pour visualiser les dashboards de monitoring.
    - URL: http://localhost:3000/
    - Utilisateur par défaut: admin
    - Mot de passe par défaut: admin (ou celui que vous avez défini dans `docker-compose/monitoring.yml`)
- **Prometheus**: Accédez à l'interface web de Prometheus pour explorer les métriques collectées.
    - URL: http://localhost:9090/

Suivez ces étapes pour configurer et lancer votre environnement de nœud Tezos avec un système de monitoring complet.
