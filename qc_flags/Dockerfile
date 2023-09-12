FROM cmap/base-clue-mts
MAINTAINER Andrew Boghossian <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY src/flagging_functions.py /src/normalization_functions.R
COPY apply_qc_flags.py /normalize.R
COPY ./aws_batch.sh /clue/bin/aws_batch

WORKDIR /
ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]

CMD ["-help"]
