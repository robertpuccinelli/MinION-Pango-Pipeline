# Pipeline/webserver_updater

This directory holds the webserver updater utilities used for translating Pangolin output into static HTML files that are hosted by an Nginx Docker container. Sample webpages are provided in the webserver/example_files directory were made with psuedo data and a sample Pangolin output file using the script listed here. The directory contains a Dockerfile for building the updater image, a requirements.txt file for installing the correct Python3 packages in the Docker image, and the data processing script that parses CSVs and turns them into crude web pages.

The sole purpose of the Dockerfile is to convert CSV files into web pages that convey uncertainty in sample classification. In the main pipeline, the Dockerfile is built into an image using the following command:
```shell
docker build ${script_path}/webserver -f server_updater.Dockerfile -t server_updater
```
`${script_path}` is the root directory of the repository and it tells the build process where to copy files from, `-f` is specifying that the Dockerfile to be built is using a non-default name, and `-t` is assigning an ID to the image once it is built.


Once the image is built, the container is launched with the following command:
```shell
docker run --rm \
    --mount type=bind,source=${DIR_DATA},target=/data/pipeline \
    --mount type=bind,source=${DIR_WATCH}/webserver,target=/data/webserver \
    server_updater
```
`--rm` will delete the container once it is stopped, the first `--mount` is specifying that a directory on the local machine will be bound to the pipeline data directory of the container, the second `--mount` is specifying that a directory on the local machine will be bound to the HTML file directory of the container, `server_updater` is the identity of the image that was built with the prior command.