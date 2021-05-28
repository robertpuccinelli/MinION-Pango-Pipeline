FROM staphb/pangolin

WORKDIR /data/
RUN mkdir /data/server

COPY ./pangolin_processing.sh /data/pangolin_processing.sh

ENTRYPOINT [ "bash", "/data/pangolin_processing.sh" ]
CMD [ "8" ]