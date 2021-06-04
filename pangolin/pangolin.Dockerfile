FROM staphb/pangolin

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /data/
RUN mkdir /data/server

COPY ./pangolin_processing.sh /data/pangolin_processing.sh

ENTRYPOINT [ "bash", "/data/pangolin_processing.sh" ]
CMD [ "8" ]