FROM lobaro/restic-backup-docker:1.2-0.9.4

ENV RCLONE_VERSION=current
ENV ARCH=amd64

ADD http://downloads.rclone.org/rclone-${RCLONE_VERSION}-linux-${ARCH}.zip /tmp/

RUN cd /tmp \
    && unzip /tmp/rclone-${RCLONE_VERSION}-linux-${ARCH}.zip \
    && mv /tmp/rclone-*-linux-${ARCH}/rclone /bin \
    && rm -r /tmp/rclone*

RUN ln -fs /root/.config /config

VOLUME ["/config"]
