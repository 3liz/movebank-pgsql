## Récupération des données Movebank

On peut voir l'aide sur le Github: https://github.com/movebank

Quelques exemples de requêtes

* Toutes les études: https://www.movebank.org/movebank/service/json?entity_type=study
* Une étude: https://www.movebank.org/movebank/service/json?entity_type=study&study_id=10857031
* Liste des individus: https://www.movebank.org/movebank/service/json?entity_type=individual&study_id=10857031
* Filtre sur un chat: https://www.movebank.org/movebank/service/public/json?study_id=10857031&individual_local_identifiers[]=Anubis2&max_events_per_individual=10000&sensor_type=gps
* Toutes les données de l'étude: https://www.movebank.org/movebank/service/public/json?study_id=10857031&max_events_per_individual=10000&sensor_type=gps

On récupère la donnée et on l'enregistre dans un fichier movebank.json, par exemple via wget

```
cd /le/bon/repertoire
wget "https://www.movebank.org/movebank/service/public/json?study_id=10857031&max_events_per_individual=10000&sensor_type=gps" -O movebank.json
```

## Création de la base de données PostgreSQL

On peut le faire à la main, ou via ligne de commande. La base s'appelle dans l'exemple `movebank`. Dans la suite, on considère que l'utilisateur PostgreSQL qui lance les requêtes est un utilisateur avec des droits élevés (superadmin).
Il faut activer l'extension PostGIS sur la base de données.

Par exemple, en ligne de commande sur un serveur Debian (commandes à lancer par exemple en tant que root)

```
su -u postgres
createdb movebank
psql -d movebank -c 'CREATE EXTENSION postgis'
psql -d movebank -c 'CREATE SCHEMA IF NOT EXISTS movebank';
```

On doit ensuite lancer le fichier SQL `movebank_structure.sql` pour créer les tables, les fonctions qui permettent d'exploiter les données brutes.

Vous pouvez l'ouvrir et le lancer à la main (via pgAdmin par exemple), ou en ligne de commande (il faut alors adapter le chemin du fichier)

```
psql -d movebank -f movebank_structure.sql
```

# Importer les données dans la base

On utilise le script Python import_movebank.py. Vu qu'il n'est pas encore paramétrable, il faut l'ouvrir avec un éditeur de texte et modifier certaines variables.

Puis le lancer, en se plaçant au préalable dans le répertoire qui contient le fichier `movebank.json`

```
cd /le/bon/repertoire
python import_movebank.py
```
