FROM staphb/artic-ncov2019:latest

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /data/
RUN mkdir /data/server \
    && mkdir /data/data_temp

COPY ./artic_processing.sh /data/artic_processing.sh

ENTRYPOINT [ "bash", "/data/artic_processing.sh" ]
CMD ["8"]