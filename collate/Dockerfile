FROM cmap/base-merino:latest
MAINTAINER Anup Jonchhe <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

COPY ./collate_bash.sh /clue/bin/collate_bash
COPY ./collate.py /clue/bin/collate.py

RUN ["chmod","-R", "+x", "/clue/bin"]

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["collate_bash"]

#CMD ["python /mk_build_file.py"]
