FROM cmap/base-clue-mts
MAINTAINER Andrew Boghossian <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./src/depmap_functions.R /src/depmap_functions.R
COPY ./make_matrices.R /make_matrices.R
COPY ./aws_batch.sh /clue/bin/aws_batch

RUN ["chmod","+x", "/make_matrices.R"]
RUN ["chmod","+x", "/src/depmap_functions.R"]

WORKDIR /
ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]

CMD ["-help"]
