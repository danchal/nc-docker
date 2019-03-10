#!/bin/sh
THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
error=
trap finish EXIT
command=$1
NEXTCLOUD_INSTANCEID=$(su www-data -s /bin/sh -c "php occ config:system:get instanceid")

finish(){
    set_maintenance_mode off
    exit $error
}

set_maintenance_mode(){
    su www-data -s /bin/sh -c "php occ maintenance:mode --$1"
}

do_borgmatic(){
    report=$(borgmatic -c ${BORG_CONFIG_DIR} --$1 2>&1)
    ret_val=$?

    echo $report

    if [ $ret_val -ne 0 ]; then
        source /app/signal.sh "FAILED - borgmatic ${1} - $(hostname): ${0} - ${THE_DATE} ${report}"
        error=1
    fi
}

do_rclone(){
    report=$(rclone $1 /repository/nextcloud gdrive-sa:nc-${NEXTCLOUD_INSTANCEID} 2>&1)
    ret_val=$?

    echo $report

    if [ $ret_val -ne 0 ]; then
        source /app/signal.sh "FAILED - rclone ${1} - $(hostname): ${0} - ${THE_DATE} ${report}"
        error=1
    fi
}

do_borgmatic prune

set_maintenance_mode on

# backup DB
mysqldump --single-transaction -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > /dbdump/nextcloud-${NEXTCLOUD_INSTANCEID}_$(date +"%Y%m%d%H%M%S").bak

do_borgmatic create

set_maintenance_mode off

# rclone
do_rclone sync

if [ $command ] && [ $command == "check" ]; then
    do_borgmatic check
fi
