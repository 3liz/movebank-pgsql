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

We need a PostgreSQL database to store the Movebank data. We assume here that you have a PostgreSQL server up and running, and that you can create a database. In the following example, we use `postgres` user, but you can obviously create a dedicated user with lower rights. 
This example has been tested under Debian and Ubuntu. Please adapt it for your distribution.

You could also use a graphical user interface such as PgAdmin to create the database and run the SQL script.

```sh
# become postgres
su -u postgres

# create the database
createdb movebank

# create postgis extension
psql -d movebank -c 'CREATE EXTENSION postgis'

# create a movebank schema
psql -d movebank -c 'CREATE SCHEMA IF NOT EXISTS movebank';
```

Your database is ready. You can now use the SQL file `movebank_structure.sql` to create the needed structure, with your graphical tool (pgAdmin) or via command line (please adapt the file path):

```sh
su -u postgres
psql -d movebank -f movebank_structure.sql
```

# Import data in the database

You can now use the Python (Python 2) script `import_movebank.py` to import the previosly downloaded data. This is a quick-and-dirty script, with no parameter nor fancy options. Please adapt it or improve it if needed. Pull request accepted ;)

You can run it from command line. Make sure the file `movebank.json` is in the same folder as the Python script.

```
cd /your/directory/
python import_movebank.py
```
