FROM cmap/base-merino:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

RUN cd /cmap && \
git clone https://github.com/cmap/merino.git && \
cd /

COPY ./assemble.py /clue/bin/assemble/assemble.py
COPY ./assemble_core.py /clue/bin/assemble/assemble_core.py
COPY ./batch_assemble.sh /clue/bin/assemble/batch_assemble
COPY ./davepool_data.py /clue/bin/assemble/davepool_data.py
COPY ./parse_data.py /clue/bin/assemble/parse_data.py
COPY ./prism_metadata.py /clue/bin/assemble/prism_metadata.py

RUN ["chmod","-R", "+x", "/clue/bin"]
WORKDIR /

ENV PATH /clue/bin/assemble/:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["batch_assemble"]
