FROM rocker/verse

MAINTAINER Andrew Boghossian <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./src/install_packages.R /src/install_packages.R
COPY ./rmarkdown/compound_report.Rmd /rmarkdown/compound_report.Rmd
COPY ./rmarkdown/drc_report.Rmd /rmarkdown/drc_report.Rmd

WORKDIR /

RUN mkdir -p /clue/bin && Rscript /src/install_packages.R

COPY ./aws_batch.sh /clue/bin/aws_batch

RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]

CMD ["-help"]
