FROM continuumio/miniconda
MAINTAINER Jacob Asiedu <cmap-soft@broadinstitute.org>
LABEL base.merino.pipeline.clue.io.version="0.0.1"
LABEL base.merino.pipeline.clue.io.vendor="Connectivity Map"

# Point APT to archived Buster repos
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    apt-get update

RUN mkdir -p /cmap/bin && \
    mkdir -p /cmap/merino/ && \
    cd /cmap/merino/

RUN which python

RUN cd /cmap && \
    conda create -y --name prism -c bioconda python=3.6 numpy pandas yaml h5py requests setuptools argparse pathlib yaml pyyaml jinja2 simplejson && \
    git clone https://github.com/cmap/cmapPy.git && \
    cd /

SHELL ["conda", "run", "-n", "prism", "/bin/bash", "-c"]

RUN cd /cmap/cmapPy && \
    python setup.py install && \
    cd /
