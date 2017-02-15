FROM ubuntu:14.04

MAINTAINER Richard Fakenberg <richard.fakenberg@gmail.com>

EXPOSE 80

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV NOMINATIM_VERSION=v2.5.1
ENV PBF_DATA=http://download.geofabrik.de/europe/monaco-latest.osm.pbf
ENV UPDATES_URL=http://download.geofabrik.de/monaco-updates

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

RUN apt-get -y update --fix-missing \
 && apt-get install -y build-essential libxml2-dev libpq-dev libbz2-dev libtool automake \
    libproj-dev libboost-dev libboost-system-dev libboost-filesystem-dev \
    libboost-thread-dev libexpat-dev gcc proj-bin libgeos-c1 libgeos++-dev \
    libexpat-dev php5 php-pear php5-pgsql php5-json php-db libapache2-mod-php5 \
    postgresql postgis postgresql-contrib postgresql-9.3-postgis-2.1 \
    postgresql-server-dev-9.3 curl git autoconf-archive cmake python \
    lua5.1 liblua5.1-dev libluabind-dev osmosis \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/*

WORKDIR /opt

RUN git clone --recursive git://github.com/twain47/Nominatim.git /opt/nominatim \
 && cd /opt/nominatim \
 && git checkout $NOMINATIM_VERSION \
 && git submodule update --recursive --init \
 && ./autogen.sh \
 && ./configure \
 && make

RUN echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/9.3/main/pg_hba.conf \
 && echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf \
 && touch /opt/nominatim/settings/local.php \
 && echo "<?php" >> /opt/nominatim/settings/local.php \
 && echo "  @define('CONST_Postgresql_Version', '9.3');" >> /opt/nominatim/settings/local.php \
 && echo "  @define('CONST_Postgis_Version', '2.1');" >> /opt/nominatim/settings/local.php \
 && echo "  @define('CONST_Website_BaseURL', '/');" >> /opt/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Url', $UPDATES_URL);" >> /opt/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_MaxInterval', '86400');" >> /opt/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Update_Interval', '86400');" >> /opt/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Recheck_Interval', '900');" >> /opt/nominatim/settings/local.php

RUN rm -rf /var/www/html/* && /opt/nominatim/utils/setup.php --create-website /var/www/html

RUN curl $PBF_DATA --create-dirs -o /opt/data.osm.pbf
RUN service postgresql start \
 && su -s /bin/bash postgres -c 'psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='nominatim'"' | grep -q 1 || su -s /bin/bash postgres -c 'createuser -s nominatim' \
 && su -s /bin/bash postgres -c 'psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='www-data'"' | grep -q 1 || su -s /bin/bash postgres -c 'createuser -SDR www-data' \ 
 && su -s /bin/bash postgres -c 'psql postgres -c "DROP DATABASE IF EXISTS nominatim"' postgress \
 && useradd -m -p password1234 nominatim \
 && su -s /bin/bash nominatim -c '/opt/nominatim/utils/setup.php --osm-file /opt/data.osm.pbf --all --threads 2' \
 && rm /opt/data.osm.pbf \
 && service postgresql stop

VOLUME /opt /var/lib/postgresql

CMD service postgresql start \
 && /usr/sbin/apache2ctl -D FOREGROUND