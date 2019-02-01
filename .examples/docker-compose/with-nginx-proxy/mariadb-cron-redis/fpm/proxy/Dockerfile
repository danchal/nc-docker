FROM linuxserver/letsencrypt
ARG dns_cloudflare_email
ARG dns_cloudflare_api_key

# set cloudflare credientials
RUN { \
        echo "dns_cloudflare_email = $dns_cloudflare_email"; \
        echo "dns_cloudflare_api_key = $dns_cloudflare_api_key"; \
} > /defaults/dns-conf/cloudflare.ini

COPY collabora-locations.conf /tmp/collabora-locations.conf
COPY nextcloud-http.conf /tmp/nextcloud-http.conf

RUN set -ex; \
    # enable nextcloud, collabora proxy configurations
    mv /defaults/proxy-confs/collabora.subdomain.conf.sample /defaults/proxy-confs/collabora.subdomain.conf; \
    mv /defaults/proxy-confs/nextcloud.subdomain.conf.sample /defaults/proxy-confs/nextcloud.subdomain.conf; \
    \
    # Nextcloud, redirect http to https
    sed -i 's|proxy_pass https://$upstream_nextcloud:443;|proxy_pass http://$upstream_nextcloud:80;|' /defaults/proxy-confs/nextcloud.subdomain.conf; \
    \
    # Nextcloud configuration is updated to running http behind proxy
    sed -i '/server *{/r /tmp/nextcloud-http.conf' /defaults/proxy-confs/nextcloud.subdomain.conf; \
    \
    # missing locations from collabora proxy config
    sed -i '/set $upstream_collabora collabora;/r /tmp/collabora-locations.conf' /defaults/proxy-confs/collabora.subdomain.conf; \
    \
    # cookie handling
    sed -i 's|#proxy_cookie_path|proxy_cookie_path|' /defaults/proxy.conf; \
    \
    # enable additional security header
    echo 'add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;' >> /defaults/ssl.conf; \
    rm -f /tmp/*

#echo 'add_header X-Robots-Tag "none" always;' >> /defaults/ssl.conf

# Optional additional headers
#add_header Content-Security-Policy "upgrade-insecure-requests";
#add_header X-Frame-Options "SAMEORIGIN" always;
#add_header X-XSS-Protection "1; mode=block" always;
#add_header X-Content-Type-Options "nosniff" always;
#add_header X-UA-Compatible "IE=Edge" always;
#add_header Cache-Control "no-transform" always;
#add_header Referrer-Policy "same-origin" always;
