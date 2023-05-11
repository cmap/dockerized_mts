FROM prismcmap/base-prism:latest
MAINTAINER Jacob Asiedu <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

#RUN echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" > /etc/apt/sources.list
#RUN sed -i 's/deb.debian.org/archive.debian.org/' /etc/apt/sources.list
#RUN apt-get update
RUN apt-get install -y jq
COPY ./merge-csvs-bash.sh /clue/bin/merge-csvs-bash
COPY ./merge_csvs.py /clue/bin/merge_csvs.py

RUN ["chmod","-R", "+x", "/clue/bin"]

RUN cd /cmap && git clone https://github.com/cmap/merino.git

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["merge-csvs-bash"]
