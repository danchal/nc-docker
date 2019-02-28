#!bin/sh

echo "Starting container ..."

# start cron
/usr/sbin/crond -f -l 8
