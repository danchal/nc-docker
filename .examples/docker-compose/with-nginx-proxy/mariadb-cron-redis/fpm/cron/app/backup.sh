#!/bin/sh
THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
THE_REPOSITORY="/repository"
BORG_PASSCOMMAND="cat /app/nextcloud-passphrase"
error=0
trap finish EXIT
command=$1

finish(){
    if [ $error -ne 0 ]; then
        set_maintenance_mode off
    fi
    exit $error
}

send_signal(){
    message="${1} - $(hostname): ${THE_DATE} - ${2}"
    source /app/signal.sh "$message"
}

handle_report(){
    if [ $2 -ne 0 ]; then
        echo "$1"
        send_signal FAILED "$1"
        error=1
    fi
}

do_validation(){
    report=""
    ret_val=0

    echo "Start: validation"

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
    handle_report "$message" $ret_val
}

do_command(){
    echo "Do: $*"
    command=$1
    p1=$2
    p2=$3
    
    case ${command} in
        borgmatic)
            report=$(borgmatic -c ${BORG_CONFIG_DIR} --${p1} 2>&1)
            ret_val=$?
            ;;
        rclone)
            report=$(rclone ${p1} ${p2} ${RCLONE_REMOTE}:${NEXTCLOUD_INSTANCEID} 2>&1)
            ret_val=$?
            ;;
        maintenancemode)
            report=$(su www-data -s /bin/sh -c "php occ maintenance:mode --${p1}" 2>&1)
            ret_val=$?
            ;;
        dbdump)
            report=$(mysqldump \
                --single-transaction \
                --result_file=/dbdump/nextcloud-${NEXTCLOUD_INSTANCEID}_$(date +"%Y%m%d%H%M%S").bak \
                -h ${MYSQL_HOST} \
                -u ${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                ${MYSQL_DATABASE} \
            2>&1)
            ret_val=$?
            ;;
        borgcheck)
            report=$(borg --info check --verify-data ${THE_REPOSITORY}* 2>&1)
            ret_val=$?
            ;;
        *)
            report="unknown command"
            ret_val=1
    esac

    handle_report "$* ${report}" ${ret_val}
}

do_validation
do_command borgmatic prune
do_command maintenancemode on
do_command dbdump
do_command borgmatic create
do_command maintenancemode off
do_command rclone sync $THE_REPOSITORY

if [ $command ] && [ $command == "check" ]; then
    do_command borgmatic check
    do_command borgcheck
    do_command rclone check $THE_REPOSITORY
fi
