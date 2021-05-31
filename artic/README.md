# Pipeline/artic

This directory holds the Artic Dockerfile and processing script that translates the MinION FASTQ/FAST5 output into an assembled FASTA file. Sample input and output files are not provided since the research that this tool was built for is currently unpublished.

The sole purpose of the Dockerfile is to blend MinION output files mounted data directory into a single `consensus_genomes.fasta` file. Many intermediate files are created during the process and are destroyed once the operation is complete. In the main pipeline, the Dockerfile is built into an image using the following command:
```shell
docker build ${script_path}/artic -f artic.Dockerfile -t artic-ncov2019
```
`${script_path}` is the root directory of the repository and it tells the build process where to copy files from, `-f` is specifying that the Dockerfile to be built is using a non-default name, and `-t` is assigning an ID to the image once it is built.


Once the image is built, the container is launched with the following command:
```shell
docker run --rm \
    --mount type=bind,source=${DIR_DATA},target=/data/server \
    artic-ncov2019 ${THREADS}
```
`--rm` will delete the container once it is stopped, `--mount` is specifying that a directory on the local machine will be bound to the server data directory of the container, `artic-ncov2019` is the identity of the image that was built with the prior command, and `${THREADS}` is the number of threads that the process is allowed to use.