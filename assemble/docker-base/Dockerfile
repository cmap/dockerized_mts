FROM continuumio/miniconda
MAINTAINER Jacob Asiedu <cmap-soft@broadinstitute.org>
LABEL base.merino.pipeline.clue.io.version="0.0.1"
LABEL base.merino.pipeline.clue.io.vendor="Connectivity Map"
RUN mkdir -p /cmap/bin && \
mkdir -p /cmap/merino/ && \
cd /cmap/merino/
#conda create -y --name merino -c bioconda python=2.7.11 numpy pandas h5py=2.6.0 requests=2.13.0 cmapPy=3.2.0 scipy setuptools argparse=1.4.0 boto3 pathlib patsy matplotlib seaborn statsmodels yaml pyyaml jinja2

RUN cd /cmap && \
conda create -y --name assemble -c bioconda python=3.6 numpy pandas yaml h5py requests setuptools argparse  pathlib  yaml pyyaml jinja2  && \
git clone https://github.com/cmap/cmapPy.git && \
cd /

SHELL ["conda", "run", "-n", "assemble", "/bin/bash", "-c"]

RUN  cd /cmap/cmapPy && \
python setup.py install && \
cd /
