FROM cmap/base-clue-mts
MAINTAINER John Davis <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"

#COPY src/flagging_functions.py /src/normalization_functions.R
#COPY apply_qc_flags.py /normalize.R
#COPY ./qc_flags_bash.sh /clue/bin/aws_batch

WORKDIR /
ENV PATH /clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["qc_flags"]

CMD ["-help"]
