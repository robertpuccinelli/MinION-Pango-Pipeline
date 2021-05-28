FROM staphb/artic-ncov2019:latest

WORKDIR /data/
RUN mkdir /data/server \
    && mkdir /data/data_temp

COPY ./artic_processing.sh /data/artic_processing.sh

ENTRYPOINT [ "bash", "/data/artic_processing.sh" ]
CMD ["8"]