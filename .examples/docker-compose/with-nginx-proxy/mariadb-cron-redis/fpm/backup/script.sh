#!/bin/sh

# code goes here.
set -ex

export THE_DATE=$(date +%Y-%m-%d-%s)
echo "Starting Backup on ${THE_DATE}"

restic-runner --repo gdrive --set nextcloud backup
