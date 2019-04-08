#!/bin/sh

# send all output to temporary log file + also to terminal
backuplog=$(mktemp)
{
    readonly THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
    readonly DO_CHECK=$2
    readonly NEXTCLOUD_INSTANCEID=$(su www-data -s /bin/sh -c "php occ config:system:get instanceid")
    readonly DBFILE="/data/dbdump-${NEXTCLOUD_INSTANCEID}_$(date +"%Y%m%d%H%M%S").bak"
    readonly ARCHIVE_NAME="${NEXTCLOUD_INSTANCEID}-{now:%Y-%m-%dT%H:%M:%S}"
    export BORG_REPO="${BASE_REPOSITORY}/nextcloud"
        
    error=0
    trap 'do_exit ${?}' EXIT INT

    do_exit(){
        LASTERR="$1"
        message="PASS - $(hostname): ${THE_DATE} - Backup"

        if [ "$LASTERR" -ne 0 ]; then
            do_command maintenancemode off
            message="FAILED - $(hostname): ${THE_DATE} - [${LASTERR}] Backup"
        fi

        echo "$message"
        /app/signal.sh "$(cat "${backuplog}")"
        [ -e "$backuplog" ] && rm -f "$backuplog"
        [ -e "$DBFILE" ] && rm -f "$DBFILE"
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
            echo "Environment variable NEXTCLOUD_INSTANCEID not set"
            error=102
        fi
        
        if [ -z "$BASE_REPOSITORY" ]; then
            echo "Environment variable BASE_REPOSITORY not set"
            error=103
        fi
        
        if [ -z "$BORG_REPO" ]; then
            echo "Environment variable BORG_REPO not set"
            error=104
        fi

        if [ -z "$BORG_PASSPHRASE" ]; then
            echo "Environment variable BORG_PASSPHRASE not set"
            error=105
        fi

        if [ -z "$ARCHIVE_NAME" ]; then
            echo "Environment variable ARCHIVE_NAME not set"
            error=106
        fi

        if [ -z "$ARCHIVE_SOURCE" ]; then
            echo "Environment variable ARCHIVE_SOURCE not set"
            error=107
        fi

        if [ -z "$ARCHIVE_PRUNE" ]; then
            echo "Environment variable ARCHIVE_PRUNE not set"
            error=108
        fi

        [ $error -ne 0 ] && exit $error
    }

    do_init(){
        # if repository directory does not exist then initialise it
        if [ ! -d  "$BORG_REPO" ]; then
            do_command borginit
        fi
    }

    do_command(){
        echo "Do: $*"
        command=$1
        p1=$2

        case ${command} in
            borginit)
                borg init --info --encryption=repokey-blake2 
                handle_return $? 109
                ;;
            borgprune)
                # allow backup prune to expand
                borg prune --info ${ARCHIVE_PRUNE}
                handle_return $? 110
                ;;
            borgcreate)
                # allow backup sources to expand
                borg create --info "::${ARCHIVE_NAME}" ${ARCHIVE_SOURCE}
                handle_return $? 111
                ;;
            borgcheck)
                borg check --info --verify-data "${BORG_REPO}/*"
                handle_return $? 112
                ;;
            rclone)
                rclone "${p1}" "${BORG_REPO}" "${RCLONE_REMOTE}:${NEXTCLOUD_INSTANCEID}"
                handle_return $? 120
                ;;
            maintenancemode)
                su www-data -s /bin/sh -c "php occ maintenance:mode --${p1}"
                handle_return $? 130
                ;;
            dbdump)
                mysqldump \
                    --single-transaction \
                    --result_file="${DBFILE}" \
                    -h "${MYSQL_HOST}" \
                    -u "${MYSQL_USER}" \
                    -p"${MYSQL_PASSWORD}" \
                    "${MYSQL_DATABASE}"
                handle_return $? 131
                ;;
            *)
                echo "unknown command<${command}>"
                handle_return 1 199
        esac
    }

    echo "Start $0 command<${DO_CHECK}>"

    do_validation
    do_init
    do_command borgprune
    do_command maintenancemode on
    do_command dbdump
    do_command borgcreate
    do_command maintenancemode off
    do_command rclone sync

    if [ "$DO_CHECK" ] && [ "$DO_CHECK" = "check" ]; then
        do_command rclone check                    # must be before borg check as borg check does change nonce file
        do_command borgcheck                       # borg check changes nonce file in repo?
    fi

    exit $error
} 2>&1 | tee -a "${backuplog}"
