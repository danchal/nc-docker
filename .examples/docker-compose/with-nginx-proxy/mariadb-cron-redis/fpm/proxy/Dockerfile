FROM jwilder/nginx-proxy:alpine

COPY uploadsize.conf /etc/nginx/conf.d/uploadsize.conf

ARG subdomain_nextcloud
COPY nextcloud.conf /etc/nginx/vhost.d/${subdomain_nextcloud}

ARG subdomain_collabora
COPY collabora.conf /etc/nginx/vhost.d/${subdomain_collabora}

RUN set -ex; \
    \
    # instead of returning a nice page, close connection for invalid requests
    sed -i "s|return 503|return 444|g" /app/nginx.tmpl  
