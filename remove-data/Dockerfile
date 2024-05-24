FROM prismcmap/base-prism
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

RUN apt-get -y update --allow-releaseinfo-change

RUN cd /cmap && \
cd /

SHELL ["conda", "run", "-n", "prism", "/bin/bash", "-c"]

RUN apt-get install -y zip curl && \
    apt-get install -y jq && \
    rm -rf /var/lib/apt/lists/*

COPY remove_data.py /clue/bin/remove_data.py
COPY aws_batch.sh /clue/bin/aws_batch

RUN ["chmod","-R", "+x", "/clue/bin"]

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]
