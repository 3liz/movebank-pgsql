BEGIN;

-- Préparation
SET search_path TO movebank,public;

-- gps_points : one point per gps raw data
CREATE TABLE gps_points (
    id serial,
    ind_name text,
    event_timestamp timestamp,
    photo text,
    geom geometry(POINT,4326)
);
ALTER TABLE movebank.gps_points ADD PRIMARY KEY (id);
CREATE INDEX gps_points_geom_idx ON movebank.gps_points (geom);


-- Fonction qui supprime et re-crée les tables dérivées à partir des données
DROP FUNCTION IF EXISTS movebank.refresh_views();
CREATE FUNCTION movebank.refresh_views()
RETURNS void AS $body$
BEGIN

    SET search_path TO movebank,public;

    -- Daily Line by individual
    DROP TABLE IF EXISTS v_daily_path;

    CREATE TABLE v_daily_path AS
    SELECT
    row_number() over() AS id,
    ind_name,
    event_timestamp::date AS ind_day,
    to_char(event_timestamp::date, 'dy') AS ind_dow,
    count(id) AS point_number,
    Min(event_timestamp) AS min_timestamp,
    Max(event_timestamp) AS max_timestamp,
    Max(event_timestamp) - Min(event_timestamp) AS duration,
    ST_Length(ST_MakeLine(geom::geometry(POINT,4326) ORDER BY event_timestamp)::geography(LINESTRING,4326)) AS path_length,
    (ST_MakeLine(geom::geometry(POINT,4326) ORDER BY event_timestamp))::geometry(LINESTRING,4326) AS geom
    FROM movebank.gps_points
    WHERE TRUE
    GROUP BY ind_name, event_timestamp::date
    ORDER BY ind_name, ind_day
    ;

    ALTER TABLE v_daily_path ADD PRIMARY KEY (id);

    -- Daily territory polygon
    DROP TABLE IF EXISTS v_daily_territory;

    CREATE TABLE v_daily_territory AS
    SELECT
    row_number() over() AS id,
    ind_name,
    event_timestamp::date AS ind_day,
    to_char(event_timestamp::date, 'dy') AS ind_dow,
    ST_Area(ST_Buffer(ST_ConcaveHull(ST_Collect(geom::geometry(POINT,4326)), 0.99), 0.00005)::geography(POLYGON,4326)) AS t_area,
    ST_Buffer(ST_ConcaveHull(ST_Collect(geom::geometry(POINT,4326)), 0.99), 0.00005)::geometry(POLYGON,4326) AS geom
    FROM gps_points
    WHERE TRUE
    GROUP BY ind_name, event_timestamp::date
    ORDER BY ind_name, ind_day
    ;
    ALTER TABLE v_daily_territory ADD PRIMARY KEY (id);

    -- Distribution of distance and speed during the hours of a day
    DROP TABLE IF EXISTS v_daily_behaviour;

    CREATE TABLE v_daily_behaviour AS
    WITH a AS (
    SELECT
    ind_name, event_timestamp,
    (lag(id,1) OVER (PARTITION BY ind_name ORDER BY event_timestamp)) AS from_id,
    id AS to_id,
    ST_Distance(geom::geography(POINT,4326), lag(geom::geography(POINT,4326),1) OVER (PARTITION BY ind_name ORDER BY event_timestamp )) AS distance,
    event_timestamp - lag(event_timestamp, 1) OVER (PARTITION BY ind_name ORDER BY event_timestamp) AS duration
    FROM gps_points
    ORDER BY ind_name, event_timestamp
    ),
    b AS (
    SELECT *, EXTRACT(EPOCH FROM duration) AS duration_s,
    CASE
        WHEN EXTRACT(EPOCH FROM duration) = 0 THEN 0
        ELSE distance / ( EXTRACT(EPOCH FROM duration)/3600 )
    END AS speed_m_h
    FROM a
    ORDER BY ind_name, event_timestamp
    )
    SELECT
    row_number() over() AS id,
    ind_name,
    EXTRACT(hour FROM event_timestamp) AS event_hour,
    count(b.to_id) AS point_number,
    sum(distance) AS distance,
    avg(speed_m_h) AS speed_m_h
    FROM b
    GROUP BY ind_name, EXTRACT(hour FROM event_timestamp)
    ORDER BY ind_name, event_hour
    ;
    ALTER TABLE v_daily_behaviour ADD PRIMARY KEY (id);

    -- 1 point per animal
    DROP TABLE IF EXISTS v_individual;

    CREATE TABLE v_individual AS
    SELECT
    row_number() over() AS id,
    ind_name,

    -- number of points
    count(id) AS point_number,

    -- min and max date
    Min(event_timestamp) AS min_timestamp,
    Max(event_timestamp) AS max_timestamp,

    -- number of days
    1 + date_part('days', (Max(event_timestamp) - Min(event_timestamp))) AS duration,

    -- photo
    concat('http://cattracker.org/wp-content/uploads/', replace(lower(ind_name), ' ','-'),'.jpg') AS photo,

    -- Area
    ST_Area(ST_Buffer(ST_ConcaveHull(ST_Collect(geom::geometry(POINT,4326)), 0.99), 0.00005)::geography(POLYGON,4326)) / 10000 AS total_area_ha,

    -- Random color
    ( '#' || ('{00, 33, 66, 99, CC, FF}'::text[])[abs((random() * 5 )::int ) + 1] || ('{00, 33, 66, 99, CC, FF}'::text[])[abs((random() * 5 )::int ) + 1] || ('{00, 33, 66, 99, CC, FF}'::text[])[abs((random() * 5 )::int ) + 1] )::text AS color,

    -- Centroid
    st_centroid(st_collect(geom::geometry(POINT,4326)))::geometry(POINT,4326) AS geom

    FROM gps_points
    GROUP BY ind_name
    ;
    ALTER TABLE v_individual ADD PRIMARY KEY (id);


END;
$body$
language 'plpgsql';


CREATE OR REPLACE FUNCTION movebank.trg_refresh_views()
RETURNS trigger AS
$BODY$
DECLARE
    res text;
BEGIN

    SELECT movebank.refresh_views() INTO res;
    RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

DROP TRIGGER IF EXISTS update_views ON movebank.gps_points;
CREATE TRIGGER update_views
AFTER INSERT OR UPDATE OF geom OR DELETE
ON movebank.gps_points
FOR EACH ROW
EXECUTE PROCEDURE movebank.trg_refresh_views();


COMMIT;
