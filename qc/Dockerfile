FROM cmap/base-clue-mts
MAINTAINER Andrew Boghossian <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./src/qc_functions.R /src/qc_functions.R
COPY ./qc.R /qc.R
COPY ./aws_batch.sh /clue/bin/aws_batch

WORKDIR /
ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]

CMD ["-help"]
