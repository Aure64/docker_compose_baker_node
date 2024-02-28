# README pour le Projet Docker Compose Tezos

Ce README guide à travers les étapes nécessaires pour configurer et lancer un nœud Tezos, importer une snapshot blockchain, et configurer le monitoring avec Prometheus, Grafana, et Netdata.

## Prérequis

- Docker et Docker Compose installés sur votre machine.
- Accès à une ligne de commande/terminal.

## Configuration

Avant de démarrer, configurez votre environnement en modifiant le fichier `.env` pour choisir le réseau (`mainnet`, `ghostnet`, `oxfordnet`, `weeklynet`) et le mode (`full`, `rolling`). Notez que `weeklynet` est uniquement disponible en mode `rolling`.

## Lancement

Exécutez les commandes suivantes pour démarrer votre nœud Tezos et le système de monitoring.

### Lancer tout avec Make

```
make all
```

Cette commande effectue les étapes suivantes automatiquement :

1. Crée le réseau Docker si nécessaire.
2. Lance le conteneur du nœud Tezos.
3. Nettoie le dossier `node_data`.
4. Télécharge la snapshot.
5. Lance le conteneur d'import.
6. Relance le conteneur du nœud après l'importation.
7. Démarre le système de monitoring.

### Arrêter et Nettoyer

Pour arrêter tous les services et nettoyer les ressources :

```
make stop
```

### Accès aux Interfaces Web

- **Netdata**: http://localhost:19999/
- **Grafana**: http://localhost:3000/ (admin/admin)
- **Prometheus**: http://localhost:9090/

Suivez ces étapes pour configurer et lancer votre environnement de nœud Tezos avec un système de monitoring complet.