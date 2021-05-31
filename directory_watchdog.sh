#!/bin/bash

# Change to directory being watched
DIR_WATCH=$1
DIR_SOURCE=${BASH_SOURCE%/*}
cd ${DIR_WATCH}

# Make log file if it does not exist
LOG=watchdog_log.txt
touch ${LOG}

function printToLog(){
    echo "$(date +"%Y/%m/%d %H:%M:%S")  -  " $1 >> ${LOG}
}

printToLog "Watchdog starting"

# Make webserver directory if it does not exists
# Add to log so it is not monitored for changes
if ! [ -d webserver ]
then
    mkdir -p ./webserver
    printToLog $(readlink -f ./webserver)
    cp $DIR_SOURCE/webserver/index.html ./webserver/index.html
fi

docker run --name=webserver --rm -d \
--mount type=bind,source=${DIR_WATCH}/webserver,target=/usr/share/nginx/html,readonly \
--publish 8528:80 \
nginx:alpine

# Pipeline will be initialized in new directories
while :
do
    for directory in $(ls -d */)
    do
        dir_path=$(readlink -f ${directory})
        if [ $(grep -c "${dir_path}" watchdog_log.txt) -eq 0 ]
        then

            # Start processing pipeline in directory

            # Add directory to log
            printToLog ${dir_path}
        fi

    done

    sleep 1m
done

docker kill webserver