#!/bin/sh

# send all output to temporary log file + also to terminal
backuplog=$(mktemp)
{
    readonly THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
    readonly THE_CONFIG=$1
    readonly THE_COMMAND=$2
    
    error=0
    trap 'do_exit ${?}' EXIT INT

    do_exit(){
        LASTERR="$1"
        message="PASS - $(hostname): ${THE_DATE} - Backup"

        if [ "$LASTERR" -ne 0 ]; then
            message="FAILED - $(hostname): ${THE_DATE} - [${LASTERR}] Backup"
        fi

        echo "$message"
        /app/signal.sh "$(cat "${backuplog}")"
        rm "$backuplog"
        exit "$LASTERR"
    }

    handle_return(){
        ret_val="$1"
        err_code="$2"

        if [ "$ret_val" -ne 0 ]; then
            error="$err_code"
        fi
    }

    do_validation(){
        echo "Do: validation"

        # error if not set
        if [ -z "$RCLONE_REMOTE" ]; then
            echo "Environment variable RCLONE_REMOTE not set"
            error=101
        fi

        if [ -z "$NEXTCLOUD_INSTANCEID" ]; then
            echo "${report} - Environment variable NEXTCLOUD_INSTANCEID not set"
            error=102
        fi
        
        if [ -z "$BASE_REPOSITORY" ]; then
            echo "${report} - Environment variable BASE_REPOSITORY not set"
            error=103
        fi
        
        if [ -z "$THE_CONFIG" ]; then
            echo "${report} - Environment variable THE_CONFIG not set"
            error=103
        fi
    }

    do_command(){
        echo "Do: $*"
        command=$1
        p1=$2

        case ${command} in
            borgprune)
                # allow backup prune to expand
                borg prune --info ${ARCHIVE_PRUNE} "${BORG_REPO}"
                handle_return $? 110
                ;;
            borgcreate)
                # allow backup sources to expand
                borg create --info "${BORG_REPO}::${ARCHIVE_NAME}" ${ARCHIVE_SOURCE}
                handle_return $? 111
                ;;
            borgcheck)
                borg check --info --verify-data "${BASE_REPOSITORY}/*"
                handle_return $? 112
                ;;
            rclone)
                rclone "${p1}" "${BASE_REPOSITORY}" "${RCLONE_REMOTE}:${NEXTCLOUD_INSTANCEID}"
                handle_return $? 120
                ;;
            maintenancemode)
                su www-data -s /bin/sh -c "php occ maintenance:mode --${p1}"
                handle_return $? 130
                ;;
            dbdump)
                mysqldump \
                    --single-transaction \
                    --result_file="/dbdump/nextcloud-${NEXTCLOUD_INSTANCEID}_$(date +"%Y%m%d%H%M%S").bak" \
                    -h "${MYSQL_HOST}" \
                    -u "${MYSQL_USER}" \
                    -p"${MYSQL_PASSWORD}" \
                    "${MYSQL_DATABASE}"
                handle_return $? 131
                ;;
            *)
                report="unknown command"
                handle_return $? 199
        esac
    }

    echo "Start $0 config<${THE_CONFIG}>, command<${THE_COMMAND}>"

    source "/app/${THE_CONFIG}.borg"

    do_validation
    do_command borgprune
    do_command maintenancemode on
    do_command dbdump
    do_command borgcreate
    do_command maintenancemode off
    do_command rclone sync

    if [ "$THE_COMMAND" ] && [ "$THE_COMMAND" = "check" ]; then
        do_command rclone check                    # must be before borg check as borg check does change nonce file
        do_command borgcheck                       # borg check changes nonce file in repo?
    fi

    exit $error
} 2>&1 | tee -a "${backuplog}"
