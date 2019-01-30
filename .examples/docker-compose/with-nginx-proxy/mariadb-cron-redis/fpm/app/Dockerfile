FROM nextcloud:fpm-alpine
COPY redis.config.php /usr/src/nextcloud/config/redis.config.php

ARG nextcloud_subdomain
COPY proxy.config.php /usr/src/nextcloud/config/proxy.config.php
RUN sed -i "s|nextcloud.example.com|$nextcloud_subdomain|g" /usr/src/nextcloud/config/proxy.config.php
