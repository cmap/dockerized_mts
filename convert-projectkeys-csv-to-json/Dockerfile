FROM amazon/aws-lambda-nodejs:14
COPY csv2json.sh /clue/bin/csv2json

WORKDIR /
COPY index.js ./
COPY package*.json ./


RUN npm install


ENV PATH=/clue/bin:$PATH
RUN ["chmod","-R", "+x", "/clue/bin"]
ENTRYPOINT ["csv2json"]
