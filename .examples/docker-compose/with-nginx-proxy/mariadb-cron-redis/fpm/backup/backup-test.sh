#!/bin/sh

# code goes here.
set -e

export THE_DATE=$(date +%Y-%m-%d-%s)
echo "Starting $0 on ${THE_DATE}"

restic-runner --repo test --set nextcloud backup
