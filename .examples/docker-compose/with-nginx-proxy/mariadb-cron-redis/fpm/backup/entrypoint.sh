#!bin/sh
set -e

echo "Starting container ..."

# initialise restic repositories - TODO
# 
# if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
#     echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
#     restic init | true
# fi

# start cron
/usr/sbin/crond -f -l 8
