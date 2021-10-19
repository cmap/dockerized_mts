FROM python:latest
MAINTAINER Jacob Asiedu <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"
RUN apt-get update -qq && \
  pip install pandas
COPY ./extract_biomarker_bash.sh /clue/bin/extract_biomarker_bash
COPY ./extract_biomarker.py /clue/bin/extract_biomarker.py

WORKDIR /

ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["extract_biomarker_bash"]

