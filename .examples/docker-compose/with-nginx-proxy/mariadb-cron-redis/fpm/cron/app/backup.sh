#!/bin/sh
THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
THE_REPOSITORY="/repository"
error=
trap finish EXIT
command=$1

finish(){
    set_maintenance_mode off
    exit $error
}

send_signal(){
    message="${1} - $(hostname): ${THE_DATE} - ${2}"
    source /app/signal.sh "$message"
}

set_maintenance_mode(){
    su www-data -s /bin/sh -c "php occ maintenance:mode --$1"
}

do_borgmatic(){
    report=$(borgmatic -c ${BORG_CONFIG_DIR} --$1 2>&1)
    ret_val=$?

    message="borgmatic ${1} $report"
    echo "$message"

    if [ $ret_val -ne 0 ]; then
        send_signal FAILED "$message"
        error=1
    fi
}

do_rclone(){
    report=$(rclone $1 $2 ${RCLONE_REMOTE}:${NEXTCLOUD_INSTANCEID} 2>&1)
    ret_val=$?

    message="rclone ${1} $report"
    echo "$message"

    if [ $ret_val -ne 0 ]; then
        send_signal FAILED "$message"
        error=1
    fi
}

do_validation(){
    report=""
    ret_val=0

    # error if not set
    if [ -z $RCLONE_REMOTE ]; then
        report="Environment variable RCLONE_REMOTE not set"
        ret_val=1
    fi

    if [ -z $NEXTCLOUD_INSTANCEID ]; then
        report="${report} - Environment variable NEXTCLOUD_INSTANCEID not set"
        ret_val=1
    fi

    message="validation $report"
    echo "$message"

    if [ $ret_val -ne 0 ]; then
        send_signal FAILED "$message"
        error=1
        exit 1
    fi
}

do_validation

do_borgmatic prune

set_maintenance_mode on

# backup DB
mysqldump --single-transaction -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > /dbdump/nextcloud-${NEXTCLOUD_INSTANCEID}_$(date +"%Y%m%d%H%M%S").bak

do_borgmatic create

set_maintenance_mode off

# rclone
do_rclone sync $THE_REPOSITORY

if [ $command ] && [ $command == "check" ]; then
    do_borgmatic check
    do_rclone check $THE_REPOSITORY
fi
