from monachus/borgmatic

ARG borg_passphrase
ARG signal_client_number

# global environment settings
ENV RCLONE_VERSION="current"
ENV RCLONE_ARCH="amd64"
ENV BORG_PASSPHRASE="${borg_passphrase}"
ENV BORG_CACHE_DIR=/cache

COPY crontab.txt /app/
COPY *.yaml /etc/borgmatic.d/
COPY *.sh /app/

RUN \
    # add required packages
    apk add --no-cache --update \
        \
        # signal messenger
        curl && \
    \
    # install build packages
    apk add --no-cache --virtual=build-dependencies \
        wget \
        unzip && \
    \
    # install rclone
    cd tmp && \
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
    /usr/bin/crontab /app/crontab.txt && \
    \
    # create and link rclone config directory to container config volume
    mkdir -p /root/.config && \
    ln -fs /config/rclone /root/.config/ && \
    \
    # update signal number
    sed -i "s|THE_TELEPHONE=+1234567890|THE_TELEPHONE=$signal_client_number|" /app/signal.sh

VOLUME ["/config", "/cache", "/source", "/repository"]

ENTRYPOINT ["/app/entrypoint.sh"]
