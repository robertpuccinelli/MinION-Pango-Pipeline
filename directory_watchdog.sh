#!/bin/bash

# Change to directory being watched
DIR_WATCH=$(realpath $1)
DIR_SOURCE=$(dirname $(realpath ${BASH_SOURCE%/*}))
PORT=8528
cd ${DIR_WATCH}

# Make log file if it does not exist
LOG=${DIR_WATCH}/watchdog_log.txt
touch ${LOG}

function printToLog(){
    echo "$(date +"%Y/%m/%d %H:%M:%S")  -  " $1 >> ${LOG}
}

printToLog "Watchdog starting"

# Make webserver directory if it does not exists
# Add to log so it is not monitored for changes
if ! [ -d webserver ]
then
    mkdir -p ${DIR_WATCH}/webserver
    printToLog $(readlink -f ./webserver)
    cp ${DIR_SOURCE}/webserver/index.html ${DIR_WATCH}/webserver/index.html
fi

docker run --name=minion-webserver --rm -d \
--mount type=bind,source=${DIR_WATCH}/webserver,target=/usr/share/nginx/html,readonly \
--publish ${PORT}:80 \
nginx:alpine

# Shutdown webserver if the watchdog stops
trap 'docker stop minion-webserver' INT TERM

printToLog $"MinION webserver launched on localhost:${PORT}"

# Pipeline will be initialized in new directories
while :
do
    for directory in $(find . -maxdepth 3 -mindepth 3 -type d)
    do
        dir_path=$(readlink -f ${directory})
        if [ $(grep -c "${dir_path}" watchdog_log.txt) -eq 0 ]
        then

            # Start processing pipeline in directory
            nohup source ${DIR_SOURCE}/processing_pipeline.sh ${dir_path} &
            
            # Add directory to log
            printToLog ${dir_path}
        fi

    done

    sleep 1m
done

docker stop minion-webserver