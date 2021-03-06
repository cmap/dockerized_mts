FROM cmap/base-clue-mts:latest
MAINTAINER Andrew Boghossian <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./src/MTS_functions.R /src/MTS_functions.R
COPY ./pre_processing.R /pre_processing.R
COPY ./calc_lfc.R /calc_lfc.R
COPY ./drc_compound.R /drc_compound.R
COPY ./aws_batch.sh /clue/bin/aws_batch

WORKDIR /
ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]

CMD ["-help"]
