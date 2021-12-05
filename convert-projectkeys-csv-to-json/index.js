const _ = require("underscore");
const fsPromises = require("fs/promises");
const Buffer = require("buffer");
const writeOutput = async function(fileName,projects){

    return await fsPromises.writeFile(fileName,JSON.stringify(projects));
}
const levels = async function(projectKeys,fileName){
    const outPath = fileName.replace(".json","_levels.json");
    const uniqueProjects = _.uniq(projectKeys, function (projectKey) {
        return projectKey.x_project_id;
    });
    const LEVELS = [
        'inst_info',
        'cell_info',
        'QC_TABLE',
        'LEVEL2_COUNT',
        'LEVEL2_MFI',
        'LEVEL3_LMFI',
        'LEVEL4_LFC',
        'LEVEL4_LFC_COMBAT',
        'LEVEL5_LFC',
        'LEVEL5_LFC_COMBAT'
    ];
    const projects = [];
    for (let index = 0; index < uniqueProjects.length; index++) {
        const currentProject = uniqueProjects[index];
        for (let index1 = 0; index1 < LEVELS.length; index1++) {
            const level = LEVELS[index1];
            const project = {x_project_id: currentProject.x_project_id, level: level};
            projects.push(project);
        }
    }
    return await writeOutput(outPath,projects);
}
const features = async function(projectKeys,fileName){
    const outPath = fileName.replace(".json","_features.json");
    const features = [
        "x-all",
        "x-ccle",
        "lin",
        "mut",
        "ge",
        "xpr",
        "cna",
        "met",
        "mirna",
        "rep",
        "prot",
        "shrna"
    ];

    const projects = [];
    for (let index = 0; index < projectKeys.length; index++) {
        const project = projectKeys[index];
        for (let index1 = 0; index1 < features.length; index1++) {
            const feature = features[index1];
            const clonedProject = Object.assign({}, project);
            clonedProject.feature = feature;
            projects.push(clonedProject);
        }
    }
    return await writeOutput(outPath,projects);
}
const searchPatterns = async function(projectKeys,fileName){
    const outPath = fileName.replace(".json","_search_pattern.json");
    const searchPatterns = [
        "discrete_associations*",
        "continuous_associations*",
        "model_table*",
        "RF_table*"
    ];

    const projects = [];
    for (let index = 0; index < projectKeys.length; index++) {
        const project = projectKeys[index];
        for (let index1 = 0; index1 < searchPatterns.length; index1++) {
            const pattern = searchPatterns[index1];
            const clonedProject = Object.assign({}, project);
            clonedProject.pattern = pattern;
            projects.push(clonedProject);
        }
    }
    return await writeOutput(outPath,projects);
}
const doAll = async function(projectKeyPath){
    const promises = [];
    const projKeys = await fsPromises.readFile(projectKeyPath,'utf-8');
    const projectKeys = JSON.parse(projKeys);
    promises.push(levels(projectKeys,projectKeyPath));
    promises.push(features(projectKeys,projectKeyPath));
    promises.push(searchPatterns(projectKeys,projectKeyPath));

    const p = await Promise.all(promises);
    return "done";
}
const allARGS = process.argv;
if(allARGS.length != 3){
    console.log("node projectKeys <compound_key_json>");
    process.exit(1);
}

const projectKey = allARGS[2];
const p = doAll(projectKey);

p.then(function(data){
    console.log(data);
    process.exit(0);
}).catch(function (err) {
    console.log(err);
    process.exit(1);
});




