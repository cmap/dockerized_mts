FROM amazon/aws-lambda-nodejs:14

RUN yum install jq -y
WORKDIR /usr/src/app
COPY index.js ./index.js
COPY analysis2clue.js ./analysis2clue.js
COPY register.sh ./register_clue
COPY package*.json ./
RUN npm install
RUN ["chmod","-R", "+x", "/usr/src/app"]
ENTRYPOINT ["/usr/src/app/register_clue"]
