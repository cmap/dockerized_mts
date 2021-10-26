FROM cmap/base-merino:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./stack_bash.sh /clue/bin/stack_bash
COPY ./stack.py /clue/bin/stack.py

RUN ["chmod","-R", "+x", "/clue/bin"]

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["stack_bash"]
