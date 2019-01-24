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

## Environment variables
1. Copy env.example and rename to .env.
2. Edit .env as required.

## Docker Build
1. Build and run the docker compose script.

        $ docker-compose build --pull
        $ docker-compose up -d

## Signal Web Gateway Configuration and 2FA Installation
[https://gitlab.com/morph027/signal-web-gateway](https://gitlab.com/morph027/signal-web-gateway)

1. The docker-compose will create the initial signal volume. The signal gateway container will fail due to not being registered yet.
1. Stop signal-web-gateway container.

        $ docker stop <signal web gateway>

1. Edit Signal config file, set the telephone number.

        $ vi <signal docker volume>/_data/.config/config.yml

1. Register your signal number by running a disposable signal-web-gateway container in an interactive mode against the newly created signal volumes.

        $ docker run --rm -it -v <signal docker volume>:/signal registry.gitlab.com/morph027/signal-web-gateway:master register

1. Restart signal gateway container.

        $ docker restart <signal web gateway>

1. Install Two-Factor Gateway app in Nextcloud.

1. Configure Two-Factor Gateway app.

        docker-compose exec --user www-data app php occ config:app:set twofactor_gateway sms_provider --value "signal" config:app:set twofactor_gateway sms_provider --value "signal"

1. Configure the Signal gateway. The Signal gateway URL=signal-web-gateway:5000.

        $ docker-compose exec --user www-data app php occ twofactorauth:gateway:configure signal

    Output:

        Please enter the URL of the Signal gateway (leave blank to use default): signal-web-gateway:5000
        Using signal-web-gateway:5000.

1. Enable 2FA for a user.