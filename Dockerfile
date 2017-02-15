FROM ubuntu:trusty

MAINTAINER Richard Fakenberg <richard.fakenberg@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

EXPOSE 80

ENV NOMINATIM_VERSION v2.5.1

RUN apt-get -y update --fix-missing \
 && apt-get install -y build-essential libxml2-dev libpq-dev libbz2-dev libtool automake \
    libproj-dev libboost-dev libboost-system-dev libboost-filesystem-dev \
    libboost-thread-dev libexpat-dev gcc proj-bin libgeos-c1 libgeos++-dev \
    libexpat-dev php5 php-pear php5-pgsql php5-json php-db libapache2-mod-php5 \
    postgresql postgis postgresql-contrib postgresql-9.3-postgis-2.1 \
    postgresql-server-dev-9.3 curl git autoconf-archive cmake python \
    lua5.1 liblua5.1-dev libluabind-dev \
    osmosis && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/*

WORKDIR /app

RUN git clone --recursive git://github.com/twain47/Nominatim.git /app/nominatim \
 && cd /app/nominatim \
 && git checkout $NOMINATIM_VERSION \
 && git submodule update --recursive --init \
 && ./autogen.sh \
 && ./configure \
 && make

RUN echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/9.3/main/pg_hba.conf \
 && echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf \
 && touch /app/nominatim/settings/local.php \
 && echo "<?php" >> /app/nominatim/settings/local.php \
 && echo "  @define('CONST_Postgresql_Version', '9.3');" >> /app/nominatim/settings/local.php \
 && echo "  @define('CONST_Postgis_Version', '2.1');" >> /app/nominatim/settings/local.php \
 && echo "  @define('CONST_Website_BaseURL', '/');" >> /app/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Url', 'http://download.geofabrik.de/monaco-updates');" >> /app/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_MaxInterval', '86400');" >> /app/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Update_Interval', '86400');" >> /app/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Recheck_Interval', '900');" >> /app/nominatim/settings/local.php

RUN rm -rf /var/www/html/* && /app/nominatim/utils/setup.php --create-website /var/www/html

ENV PBF_DATA http://download.geofabrik.de/europe/monaco-latest.osm.pbf
RUN curl $PBF_DATA --create-dirs -o /app/data.osm.pbf
RUN service postgresql start \
 && su -s /bin/bash postgres -c 'psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='nominatim'"' | grep -q 1 || su -s /bin/bash postgres -c 'createuser -s nominatim' \
 && su -s /bin/bash postgres -c 'psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='www-data'"' | grep -q 1 || su -s /bin/bash postgres -c 'createuser -SDR www-data' \ 
 && su -s /bin/bash postgres -c 'psql postgres -c "DROP DATABASE IF EXISTS nominatim"' postgress \
 && useradd -m -p password1234 nominatim \
 && su -s /bin/bash nominatim -c '/app/nominatim/utils/setup.php --osm-file /app/data.osm.pbf --all --threads 2' \
 && service postgresql stop

CMD service postgresql start \
 && /usr/sbin/apache2ctl -D FOREGROUND