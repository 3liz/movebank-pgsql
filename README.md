## Get data from Movebank API

See Api help on Github: https://github.com/movebank/movebank-api-doc/blob/master/movebank-api.md

Some JSON API call examples:

* Get a list of available studies: https://www.movebank.org/movebank/service/public/json?entity_type=study
* Check a single study: https://www.movebank.org/movebank/service/public/json?entity_type=study&study_id=10857031
* Get a list of individuals from a specific study: https://www.movebank.org/movebank/service/public/json?entity_type=individual&study_id=10857031
* Get all data for a study, for a single individual: https://www.movebank.org/movebank/service/public/json?study_id=10857031&sensor_type=gps&max_events_per_individual=10000&individual_local_identifiers[]=Ajax2
* Get all data from a study: https://www.movebank.org/movebank/service/public/json?study_id=10857031&max_events_per_individual=10&sensor_type=gps

**Warning**: Some data can be huge. Use with care, and avoid opening in browser (use wget or curl). To avoid this, I used the parameter max_events_per_individuals with a low value in the last example

You can for example download data and save it into a JSON file with the command line wget tool

```
cd /your/directory/
wget "https://www.movebank.org/movebank/service/public/json?study_id=10857031&max_events_per_individual=10000&sensor_type=gps" -O movebank.json
```

## Create the PostgreSQL database

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
