#!/bin/sh

THE_DATE=$(date '+%a %d-%b-%Y %T %Z')
error=1

report=$(borgmatic -c ${BORG_CONFIG_DIR} 2>&1)
result=$?

if [ $result -eq 0 ]; then
    echo "ok"
    error=0
else
    echo "FAILED - $report"
    source /app/signal.sh "FAILED - ${0} - $(hostname) - ${THE_DATE} ${report}"                
    echo "report sent"
fi

exit $error
