FROM ubuntu:16.04

MAINTAINER Richard Fakenberg <richard.fakenberg@gmail.com>

EXPOSE 80

ENV LANG=C.UTF-8
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

RUN apt-get update -qq \
 && apt-get upgrade -y \
 && apt-get install -y build-essential cmake g++ libboost-dev libboost-system-dev \
	libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev\
	libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev \
	postgresql-server-dev-9.5 postgresql-9.5-postgis-2.2 postgresql-contrib-9.5 \
	apache2 php php-pgsql libapache2-mod-php php-pear php-db git wget \
	postgresql postgresql-contrib osmosis \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/*

RUN useradd -d /srv/nominatim -s /bin/bash -m nominatim \
 && chmod a+x /srv/nominatim \
 && cd /srv/nominatim \
 && git clone --recursive git://github.com/twain47/Nominatim.git \
 && cd Nominatim \
 && mkdir build \
 && cd build \
 && cmake /srv/nominatim/Nominatim \
 && make

RUN service postgresql start \
 && su -s /bin/bash postgres -c 'createuser -s root' \
 && su -s /bin/bash postgres -c 'createuser -s nominatim' \
 && su -s /bin/bash postgres -c 'createuser -SDR www-data' \ 
 && service postgresql stop

RUN local=/srv/nominatim/Nominatim/build/settings/local.php \
 && touch $local \
 && echo "<?php" >> $local \
 && echo "  @define('CONST_Website_BaseURL', '/');" >> $local \
 && echo "  @define('CONST_Replication_Url', 'http://download.geofabrik.de/europe-updates/');" >> $local \
 && echo "  @define('CONST_Replication_MaxInterval', '86400');" >> $local \
 && echo "  @define('CONST_Replication_Update_Interval', '86400');" >> $local \
 && echo "  @define('CONST_Replication_Recheck_Interval', '900');" >> $local

RUN config=/etc/apache2/conf-available/nominatim.conf \
 && touch $config \
 && echo "<Directory '/srv/nominatim/Nominatim/build/website'>" >> $config \
 && echo "  Options FollowSymLinks MultiViews" >> $config \
 && echo "  AddType text/html   .php" >> $config \
 && echo "  DirectoryIndex search.php" >> $config \
 && echo "  Require all granted" >> $config \
 && echo "</Directory>" >> $config \
 && echo "" >> $config \
 && echo "Alias / /srv/nominatim/Nominatim/build/website/" >> $config \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && a2enconf nominatim

VOLUME /srv /var/lib/postgresql /var/log/apache2

CMD service postgresql start \
 && /usr/sbin/apache2ctl -D FOREGROUND