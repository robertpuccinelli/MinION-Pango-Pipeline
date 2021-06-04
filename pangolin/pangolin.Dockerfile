FROM staphb/pangolin

ENV TZ=America/Los_Angeles
RUN echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y tzdata && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean

WORKDIR /data/
RUN mkdir /data/server

COPY ./pangolin_processing.sh /data/pangolin_processing.sh

ENTRYPOINT [ "bash", "/data/pangolin_processing.sh" ]
CMD [ "8" ]