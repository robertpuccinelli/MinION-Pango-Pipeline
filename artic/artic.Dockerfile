FROM staphb/artic-ncov2019:latest

ENV TZ=America/Los_Angeles
RUN echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y tzdata && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean

WORKDIR /data/
RUN mkdir /data/server \
    && mkdir /data/data_temp

COPY ./artic_processing.sh /data/artic_processing.sh

ENTRYPOINT [ "bash", "/data/artic_processing.sh" ]
CMD ["8"]