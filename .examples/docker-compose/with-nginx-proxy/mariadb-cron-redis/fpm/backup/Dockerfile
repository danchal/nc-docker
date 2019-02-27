FROM restic/restic

# global environment settings
ENV RCLONE_VERSION="current"
ENV RCLONE_ARCH="amd64"

# install build packages
RUN \
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
    # install bash
    apk add bash && \
    \
    # get restic-runner
    wget -P /usr/bin https://raw.githubusercontent.com/alphapapa/restic-runner/master/restic-runner && \
    chmod 755 /usr/bin/restic-runner && \
    \
    # cleanup
    apk del --purge \
    build-dependencies && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/cache/apk/*

COPY crontab.txt /crontab.txt
COPY *.sh /
RUN chmod 755 /*.sh
RUN /usr/bin/crontab /crontab.txt

RUN mkdir -p /root/.config/backup
COPY restic /root/.config/backup/restic

VOLUME ["/config", "/data"]

RUN ln -fs /config/rclone /root/.config/

ENTRYPOINT ["/entrypoint.sh"]
