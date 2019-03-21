FROM nextcloud:fpm-alpine

ARG nextcloud_subdomain
COPY proxy.config.php /usr/src/nextcloud/config/proxy.config.php
RUN set -ex; \
    \
    # set the nextcloud subdomain
    sed -i "s|nextcloud.example.com|$nextcloud_subdomain|g" /usr/src/nextcloud/config/proxy.config.php; \
    \
    # create nextcloud data directory and log (before docker mounts it as a directory)
    mkdir /data; \
    touch /data/nextcloud.log; \
    chown -R www-data:root /data; \
    chmod -R g=u /data; \
    \
    # tune PHP-FPM
    # php-fpm access log, by default, prints to stdout, therfore gets caught by docker logs
    { \
        echo 'pm.max_children = 50'; \
        echo 'pm.start_servers = 6'; \
        echo 'pm.min_spare_servers = 3'; \
        echo 'pm.max_spare_servers = 10'; \
        echo 'access.log = /dev/null'; \
    } >> /usr/local/etc/php-fpm.d/www.conf
