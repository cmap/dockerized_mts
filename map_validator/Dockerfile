FROM public.ecr.aws/lambda/python:3.8


MAINTAINER Anup Jonche <cmap-soft@broadinstitute.org>
LABEL clue.mts.pipeline.clue.io.version="0.0.1"
LABEL clue.mts.pipeline.clue.io.vendor="PRISM"
# Copy function code
COPY . ${LAMBDA_TASK_ROOT}
#COPY map_validator.py ${LAMBDA_TASK_ROOT}
#COPY requirements.txt  .

RUN  pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["lambda_handler.handler"]