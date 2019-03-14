#!/bin/sh
curl --fail --silent --show-error -X POST -F "to=${SIGNAL_CLIENT_NO}" -F "message=${1}" http://signal-web-gateway:5000
