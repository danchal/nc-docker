#!/bin/sh
THE_TELEPHONE=+1234567890

curl --fail --silent --show-error -X POST -F "to=${THE_TELEPHONE}" -F "message=${1}" http://signal-web-gateway:5000
