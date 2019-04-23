#!/bin/sh

# send all output to temporary log file + also to terminal
backuplog=$(mktemp)
{
    readonly PARAM1=$1
    readonly PARAM2=$2
    readonly PARAM3=$3
    readonly PARAM4=$4
    readonly THE_DATE=$(date '+%Y-%m-%dT%H.%M.%S')
    readonly NEXTCLOUD_INSTANCEID=$(su www-data -s /bin/sh -c "php /var/www/html/occ config:system:get instanceid")
    readonly DBFILE="/data/dbdump-${NEXTCLOUD_INSTANCEID}_${THE_DATE}.bak"
    readonly ARCHIVE_NAME="${THE_DATE}"
    readonly ARCHIVE_SOURCES="/config /data /var/www/html/config /var/www/html/custom_apps /var/www/html/themes"
    readonly ARCHIVE_PRUNE="--keep-within=2d --keep-daily=7 --keep-weekly=4 --keep-monthly=-1"
    export BORG_REPO="${BASE_REPOSITORY}/nextcloud_${NEXTCLOUD_INSTANCEID}"

    # No one can answer if Borg asks these questions, it is better to just fail quickly
    # instead of hanging.
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=no
    export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no        
    
    error=0
    trap 'do_exit ${?}' INT TERM EXIT

    do_exit(){
        LASTERR="$1"
        short_message="PASS - ${THE_DATE} - Backup"
        long_message="$(cat "${backuplog}")"

        if [ "$LASTERR" -ne 0 ]; then
            do_command maintenancemode off
            short_message="FAILED - ${THE_DATE} - [${LASTERR}] Backup"
        fi

        echo "$short_message"

        su www-data -s /bin/sh -c "php /var/www/html/occ notification:generate --long-message '${long_message}' ${NEXTCLOUD_ADMIN_USER} '${short_message}'"
        /app/signal.sh "${long_message} - ${short_message}"
        [ -f "$backuplog" ] && rm -f "$backuplog"
        [ -f "$DBFILE" ] && rm -f "$DBFILE"
        [ -d "${TMP_EXTRACT}" ] && rm -rf "${TMP_EXTRACT}"
        [ -f "$dbdump_file" ] && rm -f "$dbdump_file"

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

        return $local_error
    }

    do_list_archives(){
        borg list \
            --short \
            "${BORG_REPO}"
    }

    do_restore(){
        export BORG_REPO="$1"
        archive="$2"
        restore_config="$3"

        [ -z "$BORG_REPO" ] && { echo "Error: repository not supplied"; exit 1; }
        [ -d "$BORG_REPO" ] || { echo "Error: repository does not exist <${BORG_REPO}>"; exit 1; }
        [ -z "$archive" ] \
        && { 
                echo "Warning: archive not supplied:"; \
                do_list_archives; \
                exit 0; 
            }

        do_command borgcheck "$archive" || exit $?
        do_command maintenancemode on || exit $?
                
        echo "Deleting old data files..."

        cd /data && find . -delete || exit 1
        rm -rf /var/www/html/custom_apps || exit 1
        rm -rf /var/www/html/config || exit 1
        rm -rf /var/www/html/themes || exit 1
        
        if [ "$restore_config" = "config" ]; then
            echo "Deleting old config files..."
            cd /config/signal && find . -delete || exit 1
            cd /config/borg && find . -delete || exit 1
            cd /config/rclone && find . -delete || exit 1
        fi

        readonly TMP_EXTRACT=$(mktemp -d /data/tmp_extract.XXXXXX)
        cd "$TMP_EXTRACT" || exit 1
        
        echo "Extracting archive data files..."

        borg extract \
            "::${archive}" \
            --exclude config/borg \
        || { echo "Error extracting archive"; exit 1; }

        echo "Restoring archive data files..."

        cd "${TMP_EXTRACT}"/data && find . -mindepth 1 -maxdepth 1 -exec mv {} /data/ \; || exit 1      
        mv "${TMP_EXTRACT}"/var/www/html/custom_apps /var/www/html/ || exit 1
        mv "${TMP_EXTRACT}"/var/www/html/config /var/www/html/ || exit 1
        mv "${TMP_EXTRACT}"/var/www/html/themes /var/www/html/ || exit 1

        if [ "$restore_config" = "config" ]; then
            echo "Restoring archive config files..."
            cd "${TMP_EXTRACT}"/config/signal && find . -mindepth 1 -maxdepth 1 -exec mv {} /config/signal/ \; || exit 1
            cd "${TMP_EXTRACT}"/config/rclone && find . -mindepth 1 -maxdepth 1 -exec mv {} /config/rclone/ \; || exit 1
        fi

        # get the name of the database backup file
        readonly dbdump_file="$(ls /data/dbdump-*.bak)"

        # restore database if backup exists
        if [ -f "$dbdump_file" ]; then
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
                "${MYSQL_DATABASE}" < "$dbdump_file" \
            || { echo "Error restoring nextcloud database"; exit 1; }

        else
            echo "Warning: backup of database does not exist. Manual scan of files is required"
            su www-data -s /bin/sh -c 'php /var/www/html/occ files:scan --all'
        fi

        # These commands fail "Could not open input file: occ"
        su www-data -s /bin/sh -c 'php /var/www/html/occ maintenance:mode --off'
        su www-data -s /bin/sh -c 'php /var/www/html/occ maintenance:data-fingerprint'  
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
                    --exclude data/*.log \
                    --exclude data/appdata_*/previews \
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
                su www-data -s /bin/sh -c "php /var/www/html/occ maintenance:mode --${p1}" \
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

    # Log Borg version
    borg --version

    do_validation || exit $?

    if [ "$PARAM1" = "restore" ]; then
        do_restore "$PARAM2" "$PARAM3" "$PARAM4"

    else
        do_init
        do_command borgprune
        do_command maintenancemode on
        do_command dbdump
        do_command borgcreate || exit $?
        do_command maintenancemode off

        if [ "$PARAM1" != 'nocheck' ]; then
            # borg check changes nonce file in repo, sync repo afterwards
            # only sync repo to cloud if borg check is good
            do_command borgcheck \
                && do_command rclone sync \
                && do_command rclone check
        fi
    fi

    exit $error
} 2>&1 | tee -a "${backuplog}"
