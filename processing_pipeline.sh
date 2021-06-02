#!/bin/bash

# Data directory is 1st argument
# Number of threads is optional 2nd, default of 8
# Minutes wait for change before terminating optional 3rd, default 10
DIR_DATA=$1
THREADS=${2:-8}
TERMINATE_FILE_NOT_CHANGED_MINS=${3:-10}

script_path=$(dirname $(realpath ${BASH_SOURCE%}))
LOG=${DIR_DATA}/pipeline_log.txt
touch ${LOG}

function printToLog(){
    echo "$(date +"%Y/%m/%d %H:%M:%S")  -  " $1 >> ${LOG}
}

function dirMinsSinceUpdate(){
        local time_now="$(date +"%s")"
        local last_hit="$(ls $1/* -dt | grep -m 1 "barcode")"
        local recent_barcode_dir_time="$(date +"%s" -r ${last_hit})"
        local net_time="$(($time_now-$recent_barcode_dir_time))"
        local net_mins="$(($net_time/60))"
        echo $net_mins
}

printToLog "# # # # #"
printToLog $"Pipeline starting in ${DIR_DATA}"
printToLog $"Data directory: ${DIR_DATA}"
printToLog $"Script directory: ${script_path}"

printToLog "Pulling Artic Docker Image"
docker pull staphb/artic-ncov2019
printToLog "Pulling Pangolin Docker Image"
docker pull staphb/pangolin
printToLog "Pulling Python Docker Image"
docker pull python:3.7

printToLog "Building Artic Dockerfile"
docker build ${script_path}/artic -f ${script_path}/artic/artic.Dockerfile -t artic-ncov2019
printToLog "Building Pangolin Dockerfile"
docker build ${script_path}/pangolin -f ${script_path}/pangolin/pangolin.Dockerfile -t pangolin
printToLog "Building Webserver Updater Dockerfile"
docker build ${script_path}/webserver_updater -f ${script_path}/webserver_updater/server_updater.Dockerfile -t server_updater

printToLog $"Processing directory until no changes after ${TERMINATE_FILE_NOT_CHANGED_MINS}"
last_update=$(dirMinsSinceUpdate ${DIR_DATA}/fastq_pass)
printToLog $"Last FASTQ was made ${last_update} minutes ago"

while [ ${last_update} -lt ${TERMINATE_FILE_NOT_CHANGED_MINS} ]
do

    printToLog "Looping through pipeline"
    time_start="$(date +"%s")"

    printToLog "Starting Artic Docker container"
    docker run --rm \
        --mount type=bind,source=${DIR_DATA},target=/data/server \
        artic-ncov2019 ${THREADS}
     Unable to capture errors from Artic pipeline since nearly all output is sent to stderr

    printToLog "Starting Pangolin Docker container"
    docker run --rm \
        --mount type=bind,source=${DIR_DATA},target=/data/server \
        pangolin

    printToLog "Starting webserver updater Docker container"
    docker run --rm \
        --mount type=bind,source=${DIR_DATA},target=/data/pipeline \
        --mount type=bind,source=${DIR_WATCH}/webserver,target=/data/webserver \
        server_updater

    # Limit frequency to once every 3 mins max
    time_now="$(date +"%s")"
    time_remaining=$(($((${time_start} + 180)) - ${time_now}))
    if [ ${time_remaining} -gt 0 ]
    then
        printToLog "Sleeping for ${time_remaining} seconds"
        sleep ${time_remaining}
    fi

    last_update=$(dirMinsSinceUpdate  ${DIR_DATA}/fastq_pass)
    printToLog $"Last FASTQ was made ${last_update} minutes ago"
    
done

printToLog "Processing pipeline terminating"
