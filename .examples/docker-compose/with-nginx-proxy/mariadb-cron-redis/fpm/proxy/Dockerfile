FROM jwilder/nginx-proxy:alpine

COPY custom.conf /etc/nginx/conf.d/custom.conf

# instead of returning a nice page, close connection for invalid requests
RUN sed -i "s|return 503|return 444|g" /app/nginx.tmpl
