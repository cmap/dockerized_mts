const allARGS = process.argv;
if(allARGS.length < 5){
    console.log("Wrong number of arguments");
    console.log("node index.js <projectName> <indexFile> <buildID> [<roleId>] [<is_review>]");
    process.exit(1);
}
const projectName = allARGS[2];
const indexFile = allARGS[3];
const buildID = allARGS[4];

let approved = false
let roleId = 'cmap_core';
if (allARGS.length > 5){
    roleId = allARGS[5]
    if (allARGS[6].toString() === "true") {
        console.log("approved: true")
        approved = true
    }
}

//Environment variables
const apiKey = process.env.apiKey;
const apiURL = process.env.apiURL;

const Analysis2Clue = require("./analysis2clue");
const analysis2clue = new Analysis2Clue(apiKey, apiURL, buildID,projectName, indexFile, roleId, approved);
const p = analysis2clue.start();
p.then(function(data){
    console.log(data);
    process.exit(0);
}).catch(function (err) {
    console.log(err);
    process.exit(1);
});

