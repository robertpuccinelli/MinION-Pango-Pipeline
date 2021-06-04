#!/bin/bash
THREADS=$1
DIR_DATA="/data/server"
DIR_TEMP="/tmp"
FILE_THRESHOLD=2
LOG=${DIR_DATA}/pipeline_log.txt
touch ${LOG}

function printToLog(){
    echo "$(date +"%Y/%m/%d %H:%M:%S")  -  " $1 >> ${LOG}
}
printToLog "# # # # #"
printToLog "Artic processing starting"

# Iterate through the guppy_barcoder .fasta files
barcodes_found=0
barcodes_processed=0

for barcode_dir in $(find ${DIR_DATA}/fastq_pass -maxdepth 1 -type d -name "barcode*")
do
    if [ $(ls ${barcode_dir} | wc -l) -ge ${FILE_THRESHOLD} ]
    then
        ((barcodes_found++))
        barcode_name=$(basename ${barcode_dir})
        printToLog $"Processing ${barcode_name}/fastq_pass on Artic guppyplex"

        # Filter reads for file and output to temp dir as barcode_name.fastq
        artic guppyplex \
            --skip-quality-check\
            --min-length 400 \
            --max-length 700 \
            --directory ${DIR_DATA}/fastq_pass/${barcode_name} \
            --output ${DIR_TEMP}/${barcode_name}.fastq

        printToLog $"Generating ${barcode_name} consensus sequence on Artic minion"

        # Assemble filtered reads for file
        # Assuming summary file is data_dir/barcode_name.txt
        # Assigned scheme and version to argumentss rather than free floatings
        ## Nanopolish, script completed on 4750U@3GHz and 16 threads in 17 mins
    #    artic minion \
    #        --normalise 200 --threads ${THREADS} \
    #        --scheme-directory /primer-schemes \
    #        --read-file ${DIR_TEMP}/${barcode_name}.fastq \
    #        --fast5-directory ${DIR_DATA}/fast5_pass/${barcode_name} \
    #        --sequencing-summary ${DIR_DATA}/sequencing_summary*.txt \
    #        nCoV-2019/V3 \
    #        ${DIR_TEMP}/${barcode_name}

         ## Medaka, script completed on 4750U@3GHz and 16 threads in 13 mins
        artic minion \
            --medaka \
            --medaka-model r941_min_high_g360 \
            --normalise 200 --threads ${THREADS} \
            --scheme-directory /primer-schemes \
            --read-file ${DIR_TEMP}/${barcode_name}.fastq \
            nCoV-2019/V3 \
            ${DIR_TEMP}/${barcode_name}
        ((barcodes_processed++))

        mv ${DIR_TEMP}/${barcode_name}*1.depths ${DIR_DATA}/${barcode_name}_1.depths
        mv ${DIR_TEMP}/${barcode_name}*2.depths ${DIR_DATA}/${barcode_name}_2.depths
    fi
done

if ! [ ${barcodes_found} -eq ${barcodes_processed} ]
then
    printToLog $"${barcode_name} caused an error"
fi

printToLog $"Barcode fasta files discovered: ${barcodes_found}"
printToLog $"Files successfully processed  : ${barcodes_processed}"

if [ -f ${DIR_TEMP}/*.consensus.fasta ]
then
    cat ${DIR_TEMP}/*.consensus.fasta > ${DIR_DATA}/consensus_genomes.fasta
    printToLog $"Generated ${DIR_DATA}/consensus_genomes.fasta"
fi

printToLog "End of Artic processing"
