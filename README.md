# Nominatim Docker Image
Nominatim (from the Latin, 'by name') is a tool to search OSM data by name and address 
and to generate synthetic addresses of OSM points (reverse geocoding). 
It can be found at [nominatim.openstreetmap.org](http://nominatim.openstreetmap.org/)

Nominatim project repository on GitHub: [twain47/Nominatim](https://github.com/twain47/Nominatim)

## Github
Dockerfile can be found on [fakenberg/nominatim](https://github.com/fakenberg/nominatim)

## Wiki
Usage examples: [wiki.openstreetmap.org](http://wiki.openstreetmap.org/wiki/Nominatim)

## Run container
```
docker run -d -p 80:80 --name nominatim fakenberg/nominatim:latest
```

## Download & importing OSM Data
Importing data can be found on [download.geofabrik.de](http://download.geofabrik.de)
```
docker exec -t nominatim wget http://download.geofabrik.de/europe/monaco-latest.osm.pbf
docker exec -t nominatim setup --osm-file monaco-latest.osm.pbf --all --osm2pgsql-cache 28000 --threads 2
docker exec -t nominatim rm monaco-latest.osm.pbf
```

## Updating Nominatim
Setup updating configuration
```
docker exec -t nominatim setup --osmosis-init
docker exec -t nominatim setup --create-functions --enable-diff-updates
```
Replicate OSM data with osmosis
```
docker exec -t nominatim update --import-osmosis-all --no-npi
```