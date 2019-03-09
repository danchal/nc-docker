#!/bin/sh
THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
error=
trap finish EXIT
command=$1

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

    if [ $ret_val -ne 0 ]; then
        source /app/signal.sh "FAILED - ${1} - $(hostname): ${0} - ${THE_DATE} ${report}"
        error=1
    fi
}

do_borgmatic prune

set_maintenance_mode on

do_borgmatic create

# backup DB
mysqldump --single-transaction -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > nextcloud-sqlbkp_`date +"%Y%m%d%H%M%S"`.bak

set_maintenance_mode off

# rclone

if [ $command ] && [ $command == "check" ]; then
    do_borgmatic check
fi
