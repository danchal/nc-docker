FROM jwilder/docker-gen

# get latest version of proxy template
# instead of returning a nice page, close connection for invalid requests
RUN set -ex; \
    mkdir -p /etc/docker-gen/templates; \ 
    \
    wget -P /etc/docker-gen/templates/ https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl; \
    \
    sed -i "s|return 503|return 444|g" /etc/docker-gen/templates/nginx.tmpl