# -*- coding:utf-8 -*-
import psycopg2
import json

# Variables
truncate_gps_points = True
dbname = 'movebank'
dbuser = 'movebank'
dbhost = 'localhost'
dbpass = 'movebank'

# Convert data from JSON source into Python dict
data = None
with open('movebank.json') as f:
    data = json.load(f)

inds = []
for individual in data['individuals']:
    for event in individual['locations']:
        inds.append({
            'ind_name': individual['individual_local_identifier'],
            'longitude': event['location_long'],
            'latitude': event['location_lat'],
            'timestamp': event['timestamp']
        })

# Add data directly to PostgreSQL table

try:
    conn = psycopg2.connect(
        "dbname='%s' user='%s' host='%s' password='%s'" % (
            dbname,
            dbuser,
            dbhost,
            dbpass
        )
    )
    cur = conn.cursor()

    # Truncate raw data before reimporting
    if truncate_gps_points:
        try:
            cur.execute("TRUNCATE movebank.gps_points CASCADE;")
        except:
            print("Cannot truncate gps_points")


    try:
        # Disable trigger on gps_points for performance
        cur.execute("ALTER TABLE movebank.gps_points DISABLE TRIGGER USER;")

        # Insert data into table
        cur.executemany(
            """
            INSERT INTO movebank.gps_points (
                ind_name, event_timestamp, geom
            )
            VALUES (
                %(ind_name)s,
                to_timestamp(( %(timestamp)s::real / 1000)),
                ST_SetSRID(ST_MakePoint( %(longitude)s, %(latitude)s ), 4326)
            )
            """,
            inds
        )

        # Re-enable trigger
        cur.execute("ALTER TABLE movebank.gps_points ENABLE TRIGGER USER;")

        # Insert data into derived tables
        cur.execute("SELECT movebank.refresh_views();")

        # Commit
        conn.commit()
    except:
        print("Cannot run query")
except:
    print("Cannot connect to the database")

# Write data into CSV file
import csv
with open('movebank.csv', 'wb') as csvfile:
    fieldnames = ['ind_name', 'longitude', 'latitude', 'timestamp']
    writer = csv.DictWriter(csvfile, fieldnames)
    writer.writeheader()
    writer.writerows(inds)

with open('movebank.csvt', 'wb') as csvfile:
    fieldtypes = ['string', 'real', 'real', 'integer']
    csvfile.write(','.join(fieldtypes))
