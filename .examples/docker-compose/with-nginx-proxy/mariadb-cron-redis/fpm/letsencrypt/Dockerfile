FROM linuxserver/letsencrypt
ARG dns_cloudflare_email
ARG dns_cloudflare_api_key

# set cloudflare credientials
RUN { \
        echo "dns_cloudflare_email = $dns_cloudflare_email"; \
        echo "dns_cloudflare_api_key = $dns_cloudflare_api_key"; \
} > /defaults/dns-conf/cloudflare.ini

#COPY nextcloud-http.conf /tmp/nextcloud-http.conf

RUN set -ex; \
    # enable nextcloud, collabora proxy configurations
    cp /defaults/proxy-confs/collabora.subdomain.conf.sample /defaults/proxy-confs/collabora.subdomain.conf; \
    cp /defaults/proxy-confs/nextcloud.subdomain.conf.sample /defaults/proxy-confs/nextcloud.subdomain.conf; \
    \
    # enable additional security header
    sed -i 's|#\(add_header Strict-Transport-Security*\)|\1|' /defaults/ssl.conf; \
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
