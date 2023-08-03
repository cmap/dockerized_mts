FROM cmap/base-clue-mts
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./src/metric_functions.R /src/metric_functions.R
COPY ./compound_summary.R /compound_summary.R
COPY ./aws_batch.sh /clue/bin/aws_batch
RUN chmod -R +x /*.R

WORKDIR /
ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]

CMD ["-help"]
