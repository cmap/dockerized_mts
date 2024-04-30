FROM rocker/verse:4.0.4

MAINTAINER Andrew Boghossian <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./src/install_packages.R /src/install_packages.R

RUN mkdir -p /clue/bin && Rscript /src/install_packages.R

COPY ./rmarkdown/ /rmarkdown/
COPY ./render_reports.R /render_reports.R

WORKDIR /

COPY ./aws_batch.sh /clue/bin/aws_batch

RUN ["chmod","-R", "+x", "/clue/bin"]
ENV PATH /clue/bin:$PATH
ENTRYPOINT ["aws_batch"]

CMD ["-help"]
