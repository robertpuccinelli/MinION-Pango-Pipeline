#!/bin/bash
THREADS=$1
DIR_DATA="/data/server"
DIR_TEMP="/data/temp"
LOG=${DIR_DATA}/log.txt
touch ${LOG}

function printToLog(){
    echo "$(date +"%Y/%m/%d %H:%M:%S")  -  " $1 >> ${LOG}
}
printToLog "# # # # #"
printToLog "Artic processing starting"

# Create file to record processing order to prevent data mixup with final concat
if [ -e ${DIR_DATA}/process_order.txt ]
then
    rm ${DIR_DATA}/process_order.txt
fi

touch ${DIR_DATA}/process_order.txt
printToLog "Creating ${DIR_DATA}/process_order.txt"

# Iterate through the guppy_barcoder .fasta files
files_found=0
files_processed=0

for file in $(find ${DIR_DATA} -maxdepth 1 -type f -name "*barcode*.fasta")
do
    files_found++
    # Store base name of file being operated on
    base_name= basename ${file} .fasta

    printToLog "Processing ${base_name} on guppyplex"

    # Filter reads for file and output to temp dir as base_name.fastq
    artic guppyplex \
        --min-length 400 \
        --max-length 700 \
        --directory ${DIR_DATA}/${base_name} \
        --output ${DIR_TEMP}/${base_name}.fastq \
        > ${LOG} 2>&1


    printToLog "Processing ${base_name} on minion"

    # Assemble filtered reads for file
    # Assuming summary file is data_dir/base_name.txt
    # Assigned scheme and version to argumentss rather than free floatings
    artic minion \
        --normalise 200 --threads ${THREADS} \
        --scheme-directory /primer_schemes \
        --scheme nCov-2019 --scheme_version V3 \
        --read-file ${DIR_TEMP}/${base_name}.fastq \
        --fast5-directory ${DIR_DATA} \
        --sequencing-summary ${DIR_DATA}/sequencing_summary*.txt \
        --sample ${DIR_TEMP}/${base_name} 
        > ${LOG} 2>&1

    # Record base name of file processed
    echo "${base_name}" >> ${DIR_DATA}/process_order.txt

    files_processed++
done

if ! [ ${files_found} -eq ${files_processed} ]
then
    printToLog "${base_name} caused an error"
fi

printToLog "Barcode fasta files discovered: ${files_found}"
printToLog "Files successfully processed  : ${files_processed}"

if [ -e ${DIR_TEMP}/*.consensus.fasta ]
then
    cat ${DIR_TEMP}/*.consensus.fasta > ${DIR_DATA}/consensus_genomes.fasta
    printToLog "Generated ${DIR_DATA}/consensus_genomes.fasta"
fi

printToLog "End of Artic processing"
