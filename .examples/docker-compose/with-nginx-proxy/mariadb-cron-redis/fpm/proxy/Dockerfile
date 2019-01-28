FROM linuxserver/letsencrypt
ARG dns_cloudflare_email
ARG dns_cloudflare_api_key

# set cloudflare credientials
RUN { \
        echo "dns_cloudflare_email = $dns_cloudflare_email"; \
        echo "dns_cloudflare_api_key = $dns_cloudflare_api_key"; \
} > /defaults/dns-conf/cloudflare.ini

# enable nextcloud, collabora proxy configurations
# site from search engine crawlers (robots)
RUN set -ex; \
    mv /defaults/proxy-confs/collabora.subdomain.conf.sample /defaults/proxy-confs/collabora.subdomain.conf; \
    mv /defaults/proxy-confs/nextcloud.subdomain.conf.sample /defaults/proxy-confs/nextcloud.subdomain.conf; \
    sed -i 's|\(^ *server_name .*;\)|\1\n    add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive";|' /defaults/proxy-confs/collabora.subdomain.conf; \
    sed -i 's|\(^ *server_name .*;\)|\1\n    add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive";|' /defaults/proxy-confs/nextcloud.subdomain.conf
