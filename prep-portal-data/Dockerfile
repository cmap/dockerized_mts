FROM prismcmap/base-prism:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

RUN apt-get -y update --allow-releaseinfo-change

SHELL ["conda", "run", "-n", "prism", "/bin/bash", "-c"]

RUN apt-get install -y jq & pip install google-cloud-bigquery && \
    apt-get install -y zip curl && \
    rm -rf /var/lib/apt/lists/*

# aws
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip
RUN ./aws/install && aws --version

COPY prep_portal_data.py /clue/bin/prep_portal_data.py
COPY aws_batch.sh /clue/bin/aws_batch

RUN ["chmod","-R", "+x", "/clue/bin"]

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["aws_batch"]
