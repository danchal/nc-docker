# Features
        Nextcloud
        Cron
        Redis
        fpm
        Nginx
        Letsencrypt
        Collabora
        Signal Web Gateway
        Cloudflare DDNS
        Borgbackup
        Rclone

# Setup

## Environment variables
1. Copy env.example and rename to .env .
2. Edit .env as required.

## Docker Build
1. Build and run the docker compose script.

        $ docker-compose build --pull
        $ docker-compose up -d

## Signal Web Gateway Configuration and 2FA Installation
[https://gitlab.com/morph027/signal-web-gateway](https://gitlab.com/morph027/signal-web-gateway)

1. The signal-web-gateway container will fail due to not being registered yet.
1. Stop the signal-web-gateway container.

        $ docker stop <signal web gateway>

1. Edit Signal config file, set the telephone number.

        $ vi <signal docker volume>/_data/.config/config.yml

1. Register your signal number by running a disposable signal-web-gateway container in an interactive mode against the signal docker volume.

        $ docker run --rm -it -v <signal docker volume>:/signal registry.gitlab.com/morph027/signal-web-gateway:master register

1. Restart signal-web-gateway container.

        $ docker restart <signal web gateway>

1. Install Two-Factor Gateway app in Nextcloud.

1. Configure Two-Factor Gateway app.

        $ docker-compose exec --user www-data app php occ config:app:set twofactor_gateway sms_provider --value "signal"

1. Configure the Signal Web Gateway. (URL=signal-web-gateway:5000)

        $ docker-compose exec --user www-data app php occ twofactorauth:gateway:configure signal

1. Using Nextcloud, enable 2FA for a user.

## Backup

[https://rclone.org](https://rclone.org/)

### Setup Rclone endpoints
1. Start a bash session in the cron container

        $ docker exec -it <cron> /bin/sh

1. Setup the rclone endpoint by running the interactive configuration, e.g.

        $ rclone config

# Help

## Collabora
Verify that all these url's work as expected

        https://collabora.example.com/hosting/discovery
        https://collabora.example.com/hosting/capabilities
        https://collabora.example.com/loleaflet/dist/admin/admin.html

### Spinning Wheel or documents not opening
When opening a document, if nothing happens or you get the spinning wheel:

1. Are you using test certificates?
1. Check the Nextcloud logs
1. Did you recently change the DNS records?

Try:

1. Re-apply the Collabora Online Server settings in the Nextcloud application.
1. Restart Collabora server.
1. Re-create the Nextcloud and Collabora domain certificates.

# Notes
## Restoring

docker-compose down
docker-compose run -d cron

docker exec -it knob_cron_run_1 sh

rclone sync gd:nextcloud_ocjst292xjxl /repository/nextcloud_ocjst292xjxl -P

borg list /repository/nextcloud_ocjst292xjxl/

/app/nextcloud-backup.sh restore /repository/nextcloud_ocjst292xjxl/ 2019-04-10T16:38:05 config

mysql -h "${MYSQL_HOST}" \
              -u "${MYSQL_USER}" \
              -p"${MYSQL_PASSWORD}" \
              -e "SELECT version()"
