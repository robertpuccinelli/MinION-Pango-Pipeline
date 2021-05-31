# Pipeline/pangolin

This directory holds the Pangolin Dockerfile and processing script that translates the Artic output into a Pangolin Covid19 lineage. Also included in this directory is a sample FASTA input file and its corresponding CSV output. These files are critical for validating the Docker container built from the Dockerfile. 

The sole purpose of the Dockerfile is to search for a `lineage_report.csv` file in the mounted data directory and output a CSV. In the main pipeline, the Dockerfile is built into an image using the following command:
```shell
docker build ${script_path}/pangolin -f pangolin.Dockerfile -t pangolin
```
`${script_path}` is the root directory of the repository and it tells the build process where to copy files from, `-f` is specifying that the Dockerfile to be built is using a non-default name, and `-t` is assigning an ID to the image once it is built.


Once the image is built, the container is launched with the following command:
```shell
docker run --rm \
    --mount type=bind,source=${DIR_DATA},target=/data/server \
    pangolin
```
`--rm` will delete the container once it is stopped, `--mount` is specifying that a directory on the local machine will be bound to the server data directory of the container, and `pangolin` is the identity of the image that was built with the prior command.