#!/usr/bin/env bash

function do_screen() {
    # $1 - name
    # $2 - command to execute

    if (! screen -ls | grep -q ${SESSION_NAME}); then
        screen -S ${SESSION_NAME} -dm -t $1
    else
        screen -S ${SESSION_NAME} -X screen -t $1
    fi
    sleep 1.5
    screen -S ${SESSION_NAME} -p $1 -X stuff "$2"
}


# Make sure we abort on errors or undefined variables
set -e
set -u

SESSION_NAME=${SESSION_NAME:-zwift}

if (screen -ls | grep -q ${SESSION_NAME}); then
    screen -X -S ${SESSION_NAME} -p 0 -X quit
fi

for service in proxy object container account; do
    echo "starting ${service}..."
    do_screen ${service} "/usr/bin/swift-${service}-server -v /etc/swift/${service}-server.conf"$'\n'
done

screen -S ${SESSION_NAME} -X screen -t shell
screen -DR
