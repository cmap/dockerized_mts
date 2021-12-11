const allARGS = process.argv;
if(allARGS.length != 5){
    console.log("Wrong number of arguments");
    console.log("node index.js <projectName> <indexFile> <buildID>");
    process.exit(1);
}
const projectName = allARGS[2];
const indexFile = allARGS[3];
const buildID = allARGS[4];

//Environment variables
const apiKey = process.env.apiKey;
const apiURL = process.env.apiURL;

const Analysis2Clue = require("./analysis2clue");
const analysis2clue = new Analysis2Clue(apiKey, apiURL, buildID,projectName, indexFile);
const p = analysis2clue.start();
p.then(function(data){
    console.log(data);
    process.exit(0);
}).catch(function (err) {
    console.log(err);
    process.exit(1);
});

