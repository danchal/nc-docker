#!/bin/sh

# error if not set
if [ -z "$SIGNAL_CLIENT_NO" ]; then
    echo "Environment variable SIGNAL_CLIENT_NO not set"
    error 1
fi

curl --fail --silent --show-error -X POST -F "to=${SIGNAL_CLIENT_NO}" -F "message=${1}" http://signal-web-gateway:5000
