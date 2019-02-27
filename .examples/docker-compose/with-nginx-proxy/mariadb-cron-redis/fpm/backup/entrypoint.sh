#!bin/sh
set -e

echo "Starting container ..."

# start cron
/usr/sbin/crond -f -l 8
