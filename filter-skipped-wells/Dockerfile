FROM prismcmap/base-prism:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

RUN apt-get install -y jq
COPY ./aws_batch.sh /clue/bin/filter_skipped_wells
COPY ./filter_skipped_wells.py /clue/bin/filter_skipped_wells.py

RUN ["chmod","-R", "+x", "/clue/bin"]

#RUN cd /cmap && git clone https://github.com/cmap/merino.git

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["filter_skipped_wells"]
