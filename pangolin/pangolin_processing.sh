#!/bin/bash

THREADS=$1
DIR_DATA="/data/server"
LOG=${DIR_DATA}/log.txt
touch ${LOG}

function printToLog(){
    echo "$(date +"%Y/%m/%d %H:%M:%S")  -  " $1 >> ${LOG}
}
printToLog "# # # # #"
printToLog "Pangolin processing starting"

files_processed=0
if [ -e  ${DIR_DATA}/consensus_genomes.fasta ]
then
    printToLog "Processing ${DIR_DATA}/consensus_genomes.fasta on Pangolin"


    pangolin \
        --threads ${THREADS} \
        --outdir ${DIR_DATA} \
        --outfile lineage_report.csv \
        ${DIR_DATA}/consensus_genomes.fasta \
        >> ${LOG} 2>&1

    ((files_processed++))
else
    printToLog "${DIR_DATA}/consensus_genomes.fasta was not found"
fi

if [ ${files_processed} -gt 0 ]
then
    printToLog "${DIR_DATA}/consensus_genomes.fasta processing is complete"
else
    printToLog "${DIR_DATA}/consensus_genomes.fasta failed to complete"
fi

printToLog "End of Pangolin processing"
