#!/bin/sh

# send all output to temporary log file + also to terminal
backuplog=$(mktemp)
{
    readonly THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
    readonly THE_REPOSITORY="/repository"
    readonly THE_COMMAND=$1
    export readonly BORG_PASSCOMMAND="cat /app/borg-passphrase"

    error=0
    trap 'do_exit ${?}' EXIT INT

    do_exit(){
        LASTERR="$1"
        message="PASS - $(hostname): ${THE_DATE} - Backup"
        
        if [ $LASTERR -ne 0 ]; then
            message="FAILED - $(hostname): ${THE_DATE} - [${LASTERR}] Backup"
        fi
        
        echo "$message"
        source /app/signal.sh "$(cat $backuplog)"
        rm $backuplog
        exit $LASTERR
    }

    handle_return(){
        ret_val=$1
        err_code=$2

        if [ $ret_val -ne 0 ]; then
            error=$err_code
        fi
    }

    do_validation(){
        echo "Do: validation"

        # error if not set
        if [ -z $RCLONE_REMOTE ]; then
            echo "Environment variable RCLONE_REMOTE not set"
            error=101
        fi

        if [ -z $NEXTCLOUD_INSTANCEID ]; then
            echo "${report} - Environment variable NEXTCLOUD_INSTANCEID not set"
            error=102
        fi
    }

    do_command(){
        echo "Do: $*"
        command=$1
        p1=$2
        p2=$3
        p3=$4

        case ${command} in
            borgmatic)
                borgmatic -c ${BORG_CONFIG_DIR} --${p1}
                handle_return $? 111
                ;;
            rclone)
                rclone ${p1} ${p2} ${RCLONE_REMOTE}:${NEXTCLOUD_INSTANCEID} ${p3}
                handle_return $? 112
                ;;
            maintenancemode)
                su www-data -s /bin/sh -c "php occ maintenance:mode --${p1}"
                handle_return $? 113
                ;;
            dbdump)
                mysqldump \
                    --single-transaction \
                    --result_file=/dbdump/nextcloud-${NEXTCLOUD_INSTANCEID}_$(date +"%Y%m%d%H%M%S").bak \
                    -h ${MYSQL_HOST} \
                    -u ${MYSQL_USER} \
                    -p${MYSQL_PASSWORD} \
                    ${MYSQL_DATABASE}
                handle_return $? 114
                ;;
            borgcheck)
                borg --info check --verify-data ${THE_REPOSITORY}/*
                handle_return $? 115
                ;;
            *)
                report="unknown command"
                handle_return $? 119
        esac
    }

    echo "Start $0"

    do_validation
    do_command borgmatic prune
    do_command maintenancemode on
    do_command dbdump
    do_command borgmatic create
    do_command maintenancemode off
    do_command rclone sync $THE_REPOSITORY

    if [ $THE_COMMAND ] && [ $THE_COMMAND == "check" ]; then
        do_command rclone check $THE_REPOSITORY # must be before borg check (see below)
        do_command borgmatic check              # changes nonce file in repo?
        #do_command borgcheck
    fi

    exit $error
} 2>&1 | tee -a ${backuplog}
