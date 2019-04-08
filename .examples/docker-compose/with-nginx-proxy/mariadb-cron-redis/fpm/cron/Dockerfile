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
        python3-dev; \
    \
    # install borgbackup
    pip3 install --upgrade \
        pip \
        borgbackup; \
    \
    # install rclone
    cd /tmp; \
    wget -q http://downloads.rclone.org/rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}.zip; \
    unzip /tmp/rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}.zip; \
    mv /tmp/rclone-*-linux-${RCLONE_ARCH}/rclone /usr/bin

FROM nextcloud:fpm-alpine
COPY --from=builder /usr/lib/python3.6/site-packages /usr/lib/python3.6/
COPY --from=builder /usr/bin/borg /usr/bin/
COPY --from=builder /usr/bin/borgfs /usr/bin/
COPY --from=builder /usr/bin/rclone /usr/bin/

COPY app /app

# global environment settings
ENV BORG_CACHE_DIR=/cache
ENV BORG_CONFIG_DIR=/config/borg
ENV BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no
ENV BORG_RELOCATED_REPO_ACCESS_IS_OK=no
ENV BASE_REPOSITORY=/repository
ENV RCLONE_CONFIG=/config/rclone/rclone.conf

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
        curl; \
    \
    # cleanup
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/cache/apk/*; \
    \
    # set execute bit on all shell files
    chmod 755 /app/*.sh; \
    \
    # setup crontab
    cat /app/crontab.txt >> /var/spool/cron/crontabs/root

VOLUME /cache /config /repository