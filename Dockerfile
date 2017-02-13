FROM debian:stable

MAINTAINER Richard Fakenberg <richard.fakenberg@gmail.com>

EXPOSE 8080

RUN apt-get update \
 && apt-get install -y build-essential libxml2-dev libpq-dev libbz2-dev libtool automake \
	libproj-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-thread-dev \
	libexpat-dev gcc proj-bin libgeos-c1 libgeos++-dev libexpat-dev php5 php-pear php5-pgsql \
	php5-json php-db libapache2-mod-php5 postgresql postgis postgresql-contrib \
	postgresql-9.4-postgis-2.1 postgresql-server-dev-9.4 wget

RUN wget http://www.nominatim.org/release/Nominatim-2.5.1.tar.bz2 \
 && tar xvf Nominatim-2.5.1.tar.bz2 \
 && rm Nominatim-2.5.1.tar.bz2 \
 && mv Nominatim-2.5.1 /home/nominatim \
 && cd /home/nominatim \
 && ./configure \
 && make

RUN echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/9.4/main/pg_hba.conf \
 && echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf \
 && touch /home/nominatim/settings/local.php \
 && echo "<?php\r\n" >> /home/nominatim/settings/local.php \
 && echo "  @define('CONST_Postgresql_Version', '9.4');\r\n" >> /home/nominatim/settings/local.php \
 && echo "  @define('CONST_Postgis_Version', '2.1');\r\n" >> /home/nominatim/settings/local.php \
 && echo "  @define('CONST_Website_BaseURL', '/');\r\n" >> /home/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Url', 'http://download.geofabrik.de/monaco-updates');\r\n" >> /home/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_MaxInterval', '86400');" >> /home/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Update_Interval', '86400');" >> /home/nominatim/settings/local.php \
 && echo "  @define('CONST_Replication_Recheck_Interval', '900');" >> /home/nominatim/settings/local.php
 
CMD service postgresql start \
 && /usr/sbin/apache2ctl -D FOREGROUND