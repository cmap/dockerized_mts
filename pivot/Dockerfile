FROM prismcmap/base-prism:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./pivot.py /clue/bin/pivot.py
COPY ./pivot_bash.sh /clue/bin/pivot

RUN ["chmod","-R", "+x", "/clue/bin"]

RUN cd /cmap && git clone https://github.com/cmap/merino.git

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["pivot"]
