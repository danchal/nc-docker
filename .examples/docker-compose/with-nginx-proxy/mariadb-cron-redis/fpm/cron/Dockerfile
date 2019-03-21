FROM alpine:latest as builder
ENV RCLONE_VERSION="current"
ENV RCLONE_ARCH="amd64"
RUN \
    # install build packages
    apk add --no-cache \
        wget \
        unzip \
        alpine-sdk \
        openssl-dev \
        acl-dev \
        linux-headers \
        python3-dev && \
    \
    # install borgmatic
    pip3 install --upgrade \
        pip \
        borgbackup \
        borgmatic && \
    \
    # install rclone
    cd /tmp && \
    wget -q http://downloads.rclone.org/rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}.zip && \
    unzip /tmp/rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}.zip && \
    mv /tmp/rclone-*-linux-${RCLONE_ARCH}/rclone /usr/bin

FROM nextcloud:fpm-alpine
COPY --from=builder /usr/lib/python3.6/site-packages /usr/lib/python3.6/
COPY --from=builder /usr/bin/borg /usr/bin/
COPY --from=builder /usr/bin/borgfs /usr/bin/
COPY --from=builder /usr/bin/borgmatic /usr/bin/
COPY --from=builder /usr/bin/generate-borgmatic-config /usr/bin/
COPY --from=builder /usr/bin/upgrade-borgmatic-config /usr/bin/
COPY --from=builder /usr/bin/rclone /usr/bin/

COPY app /app

ARG signal_client_number
ARG rclone_remote

# global environment settings
ENV BORG_CACHE_DIR=/cache
ENV BORG_CONFIG_DIR=/app
ENV RCLONE_REMOTE=${RCLONE_REMOTE}
ENV SIGNAL_CLIENT_NO=${SIGNAL_CLIENT_NO}
ENV ENV="/root/.ashrc"

RUN \
    # add required packages
    apk add --no-cache --update \
        \
        # borgbackup
        python3 \
        \
        # mariadb
        mariadb-client \
        \
        # signal messenger
        curl && \
    \
    # cleanup
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/cache/apk/* && \
    \
    # set execute bit on all shell files
    chmod 755 /app/*.sh && \
    \
    # setup crontab
    cat /app/crontab.txt >> /var/spool/cron/crontabs/www-data && \
    \
    # create and link rclone config directory to container config volume
    mkdir -p /root/.config && \
    ln -fs /config/rclone /root/.config/ && \
    \
    # set environment variables
    echo 'export NEXTCLOUD_INSTANCEID=$(su www-data -s /bin/sh -c "php occ config:system:get instanceid")' >> "$ENV"
