FROM prismcmap/base-prism:latest
MAINTAINER Jacob Asiedu <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

#RUN echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" > /etc/apt/sources.list
#RUN sed -i 's/deb.debian.org/archive.debian.org/' /etc/apt/sources.list
#RUN apt-get update
RUN apt-get install -y jq
COPY ./eps-prep-bash.sh /clue/bin/eps-prep-bash
COPY ./eps-prep.py /clue/bin/eps-prep.py

RUN ["chmod","-R", "+x", "/clue/bin"]

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["eps-prep-bash"]
