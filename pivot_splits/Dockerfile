FROM cmap/base-merino:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

RUN apt-get install -y jq
COPY ./pivot_splits.py /clue/bin/pivot_splits.py
COPY ./pivot_splits_bash.sh /clue/bin/pivot_splits_bash

RUN ["chmod","-R", "+x", "/clue/bin"]

RUN cd /cmap && git clone https://github.com/cmap/merino.git

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["pivot_splits_bash"]
