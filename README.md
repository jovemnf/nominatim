# Nominatim Docker Image

## Importin OSM Data
Run command into container
```
/srv/nominatim/Nominatim/build/utils/setup.php --osm-file /srv/monaco-latest.osm.pbf --all --osm2pgsql-cache 28000 --threads 2
```