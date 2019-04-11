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
        Borgbackup with restore
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

        $ docker-compose exec cron sh

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

1. Restart all the docker containers, i.e. docker-compose down && docker-compose up
1. Re-apply the Collabora Online Server settings in the Nextcloud application.
1. Restart Collabora server.
1. Re-create the Nextcloud and Collabora domain certificates.

# Restoring

1. Shutdown all the containers and then run only the cron container with its dependances, i.e. db.

        $ docker-compose down
        $ docker-compose run -d cron

1. Execute a shell in the previously created cron container, e.g.

        $ docker exec -it <cron_run container> sh

1. From within the cron container, restore the borgbackup repository, e.g.

        $ rclone sync myRemote:nextcloud_xxxxyyyy /repository/nextcloud_xxxxyyyy -P

1. Also, get the archive that you wish to restore, e.g.

        $ borg list /repository/nextcloud_xxxxyyyy

1. Then, execute the restore script, e.g.

        $ /app/nextcloud-backup.sh restore /repository/nextcloud_xxxxyyyy 2019-01-12T01:23:45 config

        Note:
        This will completely overwrite the Nextcloud Data, Configuration and Application. Do a backup before.
        The final parameter is optional, when present the signal and rclone configuration files will also be restored.        
1. If there are no errors then, shutdown and restart all the containers.

        $ docker-compose down
        $ docker-compose up -d

1. The Nextcloud instance will still be in maintenance mode, execute the following commands in the cron container:

        $ su www-data -s /bin/sh -c 'php occ maintenance:mode --off'
        $ su www-data -s /bin/sh -c 'php occ maintenance:data-fingerprint'
