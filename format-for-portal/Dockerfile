FROM rocker/verse:4.0.4

#LABEL Anup Jonchhe <prism@broadinstitute.org>

RUN apt-get update && apt-get install -y jq
COPY ./install_packages.R /src/install_packages.R

RUN mkdir -p /clue/bin && Rscript /src/install_packages.R

COPY ./scripts/ /scripts/
COPY ./format_for_portal.R /format_for_portal.R

WORKDIR /

COPY ./aws_batch.sh /clue/bin/aws_batch

RUN ["chmod","-R", "+x", "/clue/bin"]
ENV PATH=/clue/bin:$PATH
ENTRYPOINT ["aws_batch"]

CMD ["-help"]
