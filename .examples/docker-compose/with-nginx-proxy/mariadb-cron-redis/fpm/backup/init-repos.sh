#!bin/sh

echo "starting repository initialisation"

for file in /root/.config/backup/restic/repos/*
do
    repo_name=$(basename $file)
    echo "found repo_name<${repo_name}> $file"

    echo "testing if repo exists"
    stats_latest=$(restic-runner --repo ${repo_name} command stats latest)

    if [ $? -eq 0 ]; then
        echo "OK"
        echo "$stats_latest"
    else
        echo "Restic repository '${repo_name}' does not exists. Running restic init."; \
        #restic-runner --repo ${repo_name} init
        echo "after init"
    fi
done

echo "finished repository initialisation"
