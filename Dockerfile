FROM rocker/r-ver

RUN apt-get update -qq && \
  apt-get -y upgrade
RUN apt-get -y --no-install-recommends install \
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

COPY ./src /src
RUN Rscript /src/install_packages.R

COPY ./MTS_Data_Processing.R /MTS_Data_Processing.R

ENTRYPOINT ["Rscript", "MTS_Data_Processing.R"]
