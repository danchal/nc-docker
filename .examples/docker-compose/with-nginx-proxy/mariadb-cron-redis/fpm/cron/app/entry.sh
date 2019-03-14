#!/bin/sh

# use nextcloud instance id in borg repository backup path
sed -i "s/{NEXTCLOUD_INSTANCEID}/${NEXTCLOUD_INSTANCEID}/g" /app/*.yaml

source /cron.sh
