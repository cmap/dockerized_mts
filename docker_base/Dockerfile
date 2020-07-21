FROM rocker/r-ver
MAINTAINER Andrew Boghossian <cmap-soft@broadinstitute.org>
LABEL base.mts.pipeline.clue.io.version="0.0.1"
LABEL base.mts.pipeline.clue.io.vendor="PRISM"

RUN apt-get update -qq && \
  apt-get -y upgrade
RUN mkdir -p /src && apt-get -y --no-install-recommends install \
  libssl-dev \
  libxml2-dev \
  libcairo2-dev \
  libsqlite-dev \
  libmariadbd-dev \
  libmariadbclient-dev \
  libpq-dev \
  libssh2-1-dev \
  libhdf5-dev \
  libcurl4-openssl-dev

COPY ./install_packages.R /src/install_packages.R
RUN mkdir -p /clue/bin && Rscript /src/install_packages.R
