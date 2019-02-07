FROM nextcloud:fpm-alpine

ARG nextcloud_subdomain
COPY proxy.config.php /usr/src/nextcloud/config/proxy.config.php
RUN set -ex; \
    \
    # set the nextcloud subdomain
    sed -i "s|nextcloud.example.com|$nextcloud_subdomain|g" /usr/src/nextcloud/config/proxy.config.php; \
    \
    # create nextcloud data directory
    mkdir /data; \
    chown -R www-data:root /data; \
    chmod -R g=u /data; \
    \
    # tune PHP-FPM
    { \
        echo 'pm.max_children = 25'; \
        echo 'pm.start_servers = 5'; \
        echo 'pm.min_spare_servers = 2'; \
        echo 'pm.max_spare_servers = 5'; \
    } >> /usr/local/etc/php-fpm.d/www.conf
