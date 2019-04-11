#!/bin/sh

# send all output to temporary log file + also to terminal
backuplog=$(mktemp)
{
    readonly COMMAND=$1
    readonly PARAM1=$2
    readonly PARAM2=$3
    readonly PARAM3=$4
    readonly THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
    readonly NEXTCLOUD_INSTANCEID=$(su www-data -s /bin/sh -c "php occ config:system:get instanceid")
    readonly DBFILE="/data/dbdump-${NEXTCLOUD_INSTANCEID}_$(date +"%Y%m%d%H%M%S").bak"
    readonly ARCHIVE_NAME="{now:%Y-%m-%dT%H:%M:%S}"
    readonly ARCHIVE_SOURCES="/config /data /var/www/html/config /var/www/html/custom_apps /var/www/html/themes"
    readonly ARCHIVE_PRUNE="--keep-within=2d --keep-daily=7 --keep-weekly=4 --keep-monthly=-1"
    export BORG_REPO="${BASE_REPOSITORY}/nextcloud_${NEXTCLOUD_INSTANCEID}"
        
    error=0
    trap 'do_exit ${?}' INT TERM EXIT

    do_exit(){
        LASTERR="$1"
        message="PASS - ${THE_DATE} - Backup"

        if [ "$LASTERR" -ne 0 ]; then
            do_command maintenancemode off
            message="FAILED - ${THE_DATE} - [${LASTERR}] Backup"
        fi

        echo "$message"
        /app/signal.sh "$(cat "${backuplog}")"
        [ -e "$backuplog" ] && rm -f "$backuplog"
        [ -e "$DBFILE" ] && rm -f "$DBFILE"
        exit "$LASTERR"
    }

    do_validation(){
        echo "Do: validation"
        local_error=0

        # error if not set
        if [ -z "$RCLONE_REMOTES" ]; then
            echo "Environment variable RCLONE_REMOTE not set"
            local_error=101
        fi

        if [ -z "$NEXTCLOUD_INSTANCEID" ]; then
            echo "Environment variable NEXTCLOUD_INSTANCEID not set"
            local_error=102
        fi
        
        if [ -z "$BASE_REPOSITORY" ]; then
            echo "Environment variable BASE_REPOSITORY not set"
            local_error=103
        fi
        
        if [ -z "$BORG_REPO" ]; then
            echo "Environment variable BORG_REPO not set"
            local_error=104
        fi

        if [ -z "$BORG_PASSPHRASE" ]; then
            echo "Environment variable BORG_PASSPHRASE not set"
            local_error=105
        fi

        if [ -z "$ARCHIVE_NAME" ]; then
            echo "Environment variable ARCHIVE_NAME not set"
            local_error=106
        fi

        if [ -z "$ARCHIVE_SOURCES" ]; then
            echo "Environment variable ARCHIVE_SOURCES not set"
            local_error=107
        fi

        if [ -z "$ARCHIVE_PRUNE" ]; then
            echo "Environment variable ARCHIVE_PRUNE not set"
            local_error=108
        fi

        [ $local_error -ne 0 ] && exit $local_error
    }

    do_restore(){
        export BORG_REPO="$1"
        archive="$2"
        restore_config="$3"

        [ -z "$BORG_REPO" ] && { echo "Error: repository not supplied"; exit 1; }
        [ -d "$BORG_REPO" ] || { echo "Error: repository does not exist <${BORG_REPO}>"; exit 1; }
        [ -z "$archive" ] && { echo "Error: archive not supplied"; exit 1; }

        do_command maintenancemode on
        do_command borgcheck "$archive" || exit $?
        
        echo "Deleting old data files..."

        cd /data && find . -delete || exit 1
        cd /var/www/html && find . -delete || exit 1
        
        if [ "$restore_config" = "config" ]; then
            echo "Deleting old config files..."
            cd /config/signal && find . -delete || exit 1
            cd /config/borg && find . -delete || exit 1
            cd /config/rclone && find . -delete || exit 1
        fi

        TMP_EXTRACT=$(mktemp -d /data/tmp_extract.XXXXXX)
        cd "$TMP_EXTRACT" || exit 1
        
        echo "Extracting archive data files..."

        borg extract \
            "::${archive}" \
        || { echo "Error extracting archive"; exit 1; }

        echo "Restoring archive data files..."

        cd "${TMP_EXTRACT}"/data && find . -mindepth 1 -maxdepth 1 -exec mv {} /data/ \; || exit 1
        cd "${TMP_EXTRACT}"/var/www/html && find . -mindepth 1 -maxdepth 1 -exec mv {} /var/www/html/ \; || exit 1
        
        if [ "$restore_config" = "config" ]; then
            echo "Restoring archive config files..."
            cd "${TMP_EXTRACT}"/config/signal && find . -mindepth 1 -maxdepth 1 -exec mv {} /config/signal/ \; || exit 1
            cd "${TMP_EXTRACT}"/config/rclone && find . -mindepth 1 -maxdepth 1 -exec mv {} /config/rclone/ \; || exit 1
        fi

        echo "Dropping old database..."

        mysql -h "${MYSQL_HOST}" \
              -u "${MYSQL_USER}" \
              -p"${MYSQL_PASSWORD}" \
              -e "DROP DATABASE ${MYSQL_DATABASE}" \
        || { echo "Error dropping nextcloud database"; exit 1; }

        echo "Creating new database..."

        mysql -h "${MYSQL_HOST}" \
              -u "${MYSQL_USER}" \
              -p"${MYSQL_PASSWORD}" \
              -e "CREATE DATABASE ${MYSQL_DATABASE}" \
        || { echo "Error creating nextcloud database"; exit 1; }

        echo "Restoring archive database..."

        mysql -h "${MYSQL_HOST}" \
              -u "${MYSQL_USER}" \
              -p"${MYSQL_PASSWORD}" \
              "${MYSQL_DATABASE}" < "$(ls /data/dbdump-*.bak)" \
        || { echo "Error restoring nextcloud database"; exit 1; }

        echo "Run this command to turn off maintenance mode:"
        echo "su www-data -s /bin/sh -c 'php occ maintenance:mode --off'"
        echo ""
        echo "Run this command to update the sytem data-fingerprint:"
        echo "su www-data -s /bin/sh -c 'php occ maintenance:data-fingerprint'"

    }

    do_init(){
        # if repository directory does not exist then initialise it
        if [ ! -d  "$BORG_REPO" ]; then
            do_command borginit || exit $?
        fi
    }

    do_command(){
        echo "Do: $*"
        command=$1
        p1=$2
        local_error=0

        case ${command} in
            borginit)
                borg init \
                    --info \
                    --encryption=repokey-blake2 \
                || local_error=109
                ;;

            borgprune)
                borg prune \
                    --info \
                    ${ARCHIVE_PRUNE} \
                || local_error=110
                ;;

            borgcreate)
                borg create \
                    --info \
                    --exclude data/.opcache \
                    "::${ARCHIVE_NAME}" \
                    ${ARCHIVE_SOURCES} \
                || local_error=111
                ;;

            borgcheck)
                borg check \
                    --info \
                    --verify-data \
                    ${p1:+"::${p1}"} \
                || local_error=112
                ;;

            rclone)
                for rclone_remote in ${RCLONE_REMOTES}
                do
                    echo "--${rclone_remote}"

                    rclone "${p1}" \
                        "${BORG_REPO}" \
                        "${rclone_remote}/nextcloud_${NEXTCLOUD_INSTANCEID}" \
                    || local_error=120
                done
                ;;

            maintenancemode)
                su www-data -s /bin/sh -c "php occ maintenance:mode --${p1}" \
                || local_error=130
                ;;

            dbdump)
                mysqldump \
                    --single-transaction \
                    --result_file="${DBFILE}" \
                    -h "${MYSQL_HOST}" \
                    -u "${MYSQL_USER}" \
                    -p"${MYSQL_PASSWORD}" \
                    "${MYSQL_DATABASE}" \
                || local_error=131
                ;;

            *)
                echo "unknown command<${command}>"
                exit 199
        esac

        [ $local_error -ne 0 ] && error=$local_error

        echo "Do: $* - returning<$local_error>"
        return $local_error
    }

    echo "Start $0 command<$*>"

    do_validation

    if [ "$COMMAND" = "restore" ]; then
        do_restore "$PARAM1" "$PARAM2" "$PARAM3"

    else
        do_init
        do_command borgprune
        do_command maintenancemode on
        do_command dbdump
        do_command borgcreate || exit $?
        do_command maintenancemode off
        do_command rclone sync

        if [ "$COMMAND" != "nocheck" ]; then
            do_command rclone check                    # must be before borg check as borg check does change nonce file
            do_command borgcheck                       # borg check changes nonce file in repo?
        fi
    fi

    exit $error
} 2>&1 | tee -a "${backuplog}"
