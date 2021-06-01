#!/bin/bash

# Data directory is 1st argument
# Number of threads is optional 2nd, default of 8
# Minutes wait for change before terminating optional 3rd, default 10
DIR_DATA=$1
THREADS=${2:-8}
TERMINATE_FILE_NOT_CHANGED_MINS=${3:-10}

curr_path=$PWD
script_path=$(realpath ${BASH_SOURCE%/*})
LOG=${curr_path}/pipeline_log.txt
touch ${LOG}

function printToLog(){
    echo "$(date +"%Y/%m/%d %H:%M:%S")  -  " $1 >> ${LOG}
}

printToLog "# # # # #"
printToLog $"Pipeline starting in ${DIR_DATA}"

printToLog "Pulling Docker images"
docker pull staphb/artic-ncov2019
docker pull staphb/pangolin
docker pull python:3.7

printToLog "Building Dockerfiles"
docker build ${script_path}/artic -f artic.Dockerfile -t artic-ncov2019
docker build ${script_path}/pangolin -f pangolin.Dockerfile -t pangolin
docker build ${script_path}/webserver -f server_updater.Dockerfile -t server_updater


printToLog $"Processing directory until no changes after ${TERMINATE_FILE_NOT_CHANGED_MINS}"
last_mod_mins=0
while(${last_mod_mins} -lt ${TERMINATE_FILE_NOT_CHANGED_MINS})


    time_start= date +"%s"
    for file in $(find $1 -maxdepth 1 -type f -name "*barcode*.fasta")
    do
        printToLog "Starting Artic Docker container"
        docker run --rm \
            --mount type=bind,source=${DIR_DATA},target=/data/server \
            artic-ncov2019 ${THREADS}

        printToLog "Starting Pangolin Docker container"
        docker run --rm \
            --mount type=bind,source=${DIR_DATA},target=/data/server \
            pangolin

        printToLog "Starting webserver updater Docker container"
        docker run --rm \
            --mount type=bind,source=${DIR_DATA},target=/data/pipeline \
            --mount type=bind,source=${DIR_WATCH}/webserver,target=/data/webserver \
            server_updater
    done

    # Limit frequency to once every 3 mins max
    time_now= date +"%s"
    time_remaining= expr $(expr ${time_start} + 180) - ${time_now}
    if [${time_remaining} -gt 0]
    then
        sleep ${time_remaining}
    fi

    # Find most recently changed guppy_barcoder file
    last_mod_mins=${TERMINATE_FILE_NOT_CHANGED_MINS}
    for file in $(find $1 -maxdepth 1 -type f -name "*barcode*.fasta")
    do
        file_mod_mins=$(($(date +%m) - $(date +%m -r $file)))
        if [ ${file_mod_mins} -lt ${last_mod_mins}]
        then
            last_mod_mins=${file_mod_mins}
        fi
    done

    printToLog $"Last modification time was ${last_mod_mins} minutes ago"

done    

printToLog "Processing pipeline terminating"