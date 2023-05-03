FROM prismcmap/base-merino:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

#RUN cd /cmap && \
#conda create -y --name assemble -c bioconda python=3.6 numpy pandas yaml h5py requests setuptools argparse  pathlib  yaml pyyaml jinja2  && \
#git clone https://github.com/cmap/cmapPy.git && \
#cd /
#
#SHELL ["conda", "run", "-n", "assemble", "/bin/bash", "-c"]
#
#RUN  cd /cmap/cmapPy && \
#python setup.py install && \
#cd /


RUN mkdir -p /clue/bin/assemble/utils/

COPY ./assemble.py /clue/bin/assemble/assemble.py
COPY ./setup_logger.py /clue/bin/assemble/setup_logger.py
COPY ./utils/exceptions.py /clue/bin/assemble/utils/exceptions.py
COPY ./utils/path_utils.py /clue/bin/assemble/utils/path_utils.py
COPY ./assemble_core.py /clue/bin/assemble/assemble_core.py
COPY ./batch_assemble.sh /clue/bin/assemble/batch_assemble
COPY ./davepool_data.py /clue/bin/assemble/davepool_data.py
COPY ./parse_data.py /clue/bin/assemble/parse_data.py
COPY ./prism_metadata.py /clue/bin/assemble/prism_metadata.py

RUN ["chmod","-R", "+x", "/clue/bin"]
WORKDIR /

ENV PATH /clue/bin/assemble/:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["batch_assemble"]
