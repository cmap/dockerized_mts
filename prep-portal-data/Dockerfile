FROM cmap/base-merino:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

RUN cd /cmap && \
conda create -y --name prism python=3.6 numpy pandas simplejson  && \
cd /

SHELL ["conda", "run", "-n", "prism", "/bin/bash", "-c"]

RUN apt-get install -y jq

COPY prep_portal_data.py /clue/bin/prep_portal_data.py
COPY aws_batch.sh /clue/bin/aws_batch

RUN ["chmod","-R", "+x", "/clue/bin"]

RUN cd /cmap && git clone https://github.com/cmap/merino.git

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]
