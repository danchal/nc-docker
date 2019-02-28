#!/bin/sh
export BORG_DATE=$(date +%Y-%m-%d-%s)

echo "Starting Backup on ${BORG_DATE}"
export BORG_PASSPHRASE="$BACKUP_ENCRYPTION_KEY"

echo "  Starting Variable Setup"
export BORG_REPO="/backup/${BACKUP_NAME}"
echo "  Ending Variable Setup"

echo "  Starting Borg Backup"
if [[ ! -d "$BORG_REPO" ]]; then
    echo "    Initializing Repoistory"
    mkdir -p "$BORG_REPO"
    borg init --encryption=repokey-blake2 "$BORG_REPO"
fi

echo "    Creating Daily Archive"
borg create "$BORG_REPO"::"${BORG_DATE}" /data
echo "    END-Creating Daily Archive"


if [[ $BACKUP_PRUNE ]]; then
    echo "    Pruning Daily Archive"
    borg prune $BACKUP_PRUNE "${BORG_REPO}"
    echo "    END-Pruning Daily Archive"
fi

echo "  Ending Borg Backup"

#echo "  Starting Rclone"
#rclone sync --transfers 16 "$BORG_REPO" "$BACKUP_LOCATION"
#echo "  Ending Rclone"

echo "Ending Backup"
