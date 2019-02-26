FROM alpine:latest

ENV RCLONE_VERSION=current
ENV ARCH=amd64
ENV BACKUP_ENCRYPTION_KEY=''
ENV BACKUP_PRUNE=''
ENV BACKUP_NAME='default'

RUN apk --no-cache add ca-certificates fuse wget borgbackup\
    && cd /tmp \
    && wget -q http://downloads.rclone.org/rclone-${RCLONE_VERSION}-linux-${ARCH}.zip \
    && unzip /tmp/rclone-${RCLONE_VERSION}-linux-${ARCH}.zip \
    && mv /tmp/rclone-*-linux-${ARCH}/rclone /usr/bin \
    && rm -r /tmp/rclone*

ADD crontab.txt /crontab.txt
ADD script.sh /script.sh
COPY entry.sh /entry.sh
RUN chmod 755 /script.sh /entry.sh
RUN /usr/bin/crontab /crontab.txt

# forward log and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/script.log \
        && ln -sf /dev/stderr /var/log/script-error.log

CMD ["/entry.sh"]
