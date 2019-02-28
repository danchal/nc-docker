#!/bin/sh

THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
THE_TELEPHONE=+1234567890
THE_COMMAND=$1
THE_REPO=$2
THE_SET=$3

error=1

MESSAGE_HEADER="FAILED - cron backup - $(hostname)"
MESSAGE_SUBJECT="${THE_DATE}, COMMAND=${THE_COMMAND}, REPO=${THE_REPO}, SET=${THE_SET}"

echo "Starting $0 on ${MESSAGE_SUBJECT}"

report=$(restic-runner --repo ${THE_REPO} ${THE_SET:+--set $THE_SET} ${THE_COMMAND})
result=$?

if [ $result -eq 0 ]; then
    echo "ok"
    error=0
else
    echo "FAILED - sending report"
    curl -X POST -F "to=${THE_TELEPHONE}" -F "message=${MESSAGE_HEADER}____${MESSAGE_SUBJECT}____${report}" http://signal-web-gateway:5000
fi

exit $error
