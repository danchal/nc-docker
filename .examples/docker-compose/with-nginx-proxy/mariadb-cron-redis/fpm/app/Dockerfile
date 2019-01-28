FROM nextcloud:fpm-alpine
#ARG trusted_proxies="  'trusted_proxies' => ['letsencrypt'], 'overwrite.cli.url' => 'https://nextcloud.xx99.ml', 'overwritehost' => 'nextcloud.xx99.ml', 'overwriteprotocol' => 'https',"

COPY redis.config.php /usr/src/nextcloud/config/redis.config.php
#RUN sed -i "/);/i ${trusted_proxies}" /usr/src/nextcloud/config/config.php