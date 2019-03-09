FROM nextcloud:fpm-alpine

ARG borg_passphrase
ARG signal_client_number

# global environment settings
ENV BORG_PASSPHRASE="${borg_passphrase}"
ENV BORG_CACHE_DIR=/cache
ENV BORG_CONFIG_DIR=/app
ENV RCLONE_VERSION="current"
ENV RCLONE_ARCH="amd64"

COPY crontab.txt /app/
COPY *.yaml /app/
COPY *.sh /app/

RUN \
    # add required packages
    apk add --no-cache --update \
        \
        # borgbackup
        python3 \
        \
        # signal messenger
        curl && \
    \
    # install build packages
    apk add --no-cache --virtual=build-dependencies \
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
    mv /tmp/rclone-*-linux-${RCLONE_ARCH}/rclone /usr/bin && \
    \
    # cleanup
    apk del --purge \
        build-dependencies && \
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
    # update signal number
    sed -i "s|THE_TELEPHONE=+1234567890|THE_TELEPHONE=$signal_client_number|" /app/signal.sh

VOLUME ["/config", "/cache", "/data", "/repository"]
