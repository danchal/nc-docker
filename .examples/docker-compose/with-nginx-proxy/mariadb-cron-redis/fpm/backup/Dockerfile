FROM restic/restic

# global environment settings
ENV RCLONE_VERSION="current"
ENV RCLONE_ARCH="amd64"

ARG signal_client_number

# use local copy of restic-runner until fixed
COPY restic-runner /usr/bin

RUN \
    # add required packages
    apk add --update \
        \
        # restic-runner	
        coreutils bash bc
        \
        # signal messenger
        curl
        \
        # borg-backup
        borgebackup && \
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
    # get restic-runner
    #wget -P /usr/bin https://raw.githubusercontent.com/alphapapa/restic-runner/master/restic-runner && \
    chmod 755 /usr/bin/restic-runner && \
    \
    # cleanup
    apk del --purge \
    build-dependencies && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/cache/apk/*

VOLUME ["/config", "/data"]

# cron and config files
COPY crontab.txt /crontab.txt
COPY *.sh /
COPY restic /root/.config/backup/restic

RUN \
    # set execute bit on all shell files
    chmod 755 /*.sh && \
    \
    # setup crontab
    usr/bin/crontab /crontab.txt && \
    \
    # create and link rclone config directory to container config volume
    mkdir -p /root/.config/backup && \
    ln -fs /config/rclone /root/.config/ && \
    \
    # update signal number
    sed -i "s|THE_TELEPHONE=+1234567890|THE_TELEPHONE=$signal_client_number|" /restic.sh

ENTRYPOINT ["/entrypoint.sh"]
