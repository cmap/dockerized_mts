const _ = require("underscore");
const { ArgumentParser } = require('argparse');
const fsPromises = require("fs/promises");
const Buffer = require("buffer");

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

/**
 *
 * @param fileName
 * @param projects
 * @returns {Promise<*>}
 */
const writeOutput = async function(fileName,projects){
    return await fsPromises.writeFile(fileName,JSON.stringify(projects));
}

const getProjectsWithCombinations = function(projectKeys){
    return _.pluck(_.uniq(projectKeys.filter(function(projectKey){
        return projectKey.is_combination === '1';
    }), function (projectKey) {
        return projectKey.x_project_id;
    }), "x_project_id");
}

/**
 *
 * @param projectKeys
 * @returns {*}
 */
const uniqueProjects= function(projectKeys){
    const projectsWithCombinations =  getProjectsWithCombinations(projectKeys);

    const out = _.uniq(projectKeys, function (projectKey) {
        return projectKey.x_project_id;
    })

    out.forEach((project) => {
        if (projectsWithCombinations.includes(project.x_project_id)) {
            project.combination_project = '1'
        } else {
            project.combination_project = '0'
        }
    })

    return out;
}

const uniquePertPlates = function (projectKeys) {
    return _.uniq(projectKeys, function (projectKey) {
        return projectKey.pert_plate;
    });
}

const detectCombinations = function (projectKeys) {
    return projectKeys.forEach((compound) => {
            //check if compound.pert_iname has | character
            if (compound.pert_iname.includes("|")) {
                compound.is_combination = '1'
            } else{
                compound.is_combination = '0'
            }
        })
}

const uniqueProjectKeysWithPertPlates = async function(projectKeys,fileName){
    const outPath = fileName.replace(".json","_uniq_pert_plates.json");
    const projectsPertPlates = _.map(
        _.uniq(projectKeys, function (projectKey) {
            return [projectKey.x_project_id,projectKey.pert_plate].join('_');
        }),
        function(key) {
            return { x_project_id: key.x_project_id, pert_plate: key.pert_plate };
        }
    );
    return await writeOutput(outPath,projectsPertPlates);
}
/**
 *
 * @param projectKeys
 * @param fileName
 * @returns {Promise<*>}
 */
const uniques= async function(projectKeys,fileName){
    const outPath = fileName.replace(".json","_uniques.json");
    const uniqueProjectKeys = uniqueProjects(projectKeys);
    return await writeOutput(outPath,uniqueProjectKeys);
}
/**
 *
 * @param projectKeys
 * @param fileName
 * @returns {Promise<*>}
 */
const levels = async function(projectKeys,fileName, LEVELS){
    const outPath = fileName.replace(".json","_levels.json");
    const uniqueProjectKeys = uniqueProjects(projectKeys)
    const projects = [];
    for (let index = 0; index < uniqueProjectKeys.length; index++) {
        const currentProject = uniqueProjectKeys[index];
        for (let index1 = 0; index1 < LEVELS.length; index1++) {
            const level = LEVELS[index1];
            const project = {x_project_id: currentProject.x_project_id, level: level};
            projects.push(project);
        }
    }
    return await writeOutput(outPath,projects);
}
/**
 *
 * @param projectKeys
 * @param fileName
 * @returns {Promise<*>}
 */
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

    const sortedProjectKeys = _.sortBy(projects, function(proj){
        switch (proj.feature){
            case 'lin':
                return 1
            case 'mut':
                return 1
            case 'ge':
                return 1
            case 'xpr':
                return 1
            case 'cna':
                return 1
            case 'met':
                return 1
            case 'mirna':
                return 1
            case 'rep':
                return 1
            case 'prot':
                return 1
            case 'shrna':
                return 1
            case 'x-all':
                return 2
            case 'x-ccle':
                return 2
        }
    });


    return await writeOutput(outPath,sortedProjectKeys);
}
/**
 *
 * @param patterns
 * @param projectKeys
 * @returns {[]}
 */
const searchPatterns = function(patterns,projectKeys){
    const projects = [];
    for (let index = 0; index < projectKeys.length; index++) {
        const project = projectKeys[index];
        for (let index1 = 0; index1 < patterns.length; index1++) {
            const pattern = patterns[index1];
            const clonedProject = Object.assign({}, project);
            clonedProject.pattern = pattern;
            projects.push(clonedProject);
        }
    }
    return projects;
}
/**
 *
 * @param projectKeys
 * @param fileName
 * @returns {Promise<*>}
 */
const uniqueProjectsWithSearch = async function(projectKeys,fileName){
    const outPath = fileName.replace(".json","_proj_search_pattern.json");
    const uniqueProjectKeys = uniqueProjects(projectKeys);
    const patterns = [
        "continuous_associations.csv",
        "discrete_associations.csv",
        "DRC_TABLE.csv",
        "model_table.csv",
        "RF_table.csv"
    ];
    const projects = searchPatterns(patterns,uniqueProjectKeys);
    return await writeOutput(outPath,projects);
}
const uniqueProjectsWithCombinationSearch = async function(projectKeys,fileName){
    const outPath = fileName.replace(".json","_comb_search_pattern.json");
    const combinationsOnly = projectKeys.filter(function(projectKey){
        return projectKey.is_combination === '1';
    })
    const uniqueProjectKeys = uniqueProjects(combinationsOnly);
    const patterns = [
        "synergy_table.csv",
        "bliss_mss_table.csv"
    ];
    const projects = searchPatterns(patterns,uniqueProjectKeys);
    return await writeOutput(outPath,projects);
}
/**
 *
 * @param projectKeys
 * @param fileName
 * @returns {Promise<*>}
 */
const searchProjectPatterns = async function(projectKeys,fileName){
    const outPath = fileName.replace(".json","_search_pattern.json");
    const patterns = [
        "discrete_associations*",
        "continuous_associations*",
        "model_table*",
        "RF_table*"
    ];
    const projects = searchPatterns(patterns,projectKeys);
    return await writeOutput(outPath,projects);
}
/**
 *
 * @param projectKeyPath
 * @returns {Promise<string>}
 */
const doAll = async function(projectKeyPath,args){
    const promises = [];
    const projKeys = await fsPromises.readFile(projectKeyPath,'utf-8');
    const projectKeys = JSON.parse(projKeys);
    const LEVELS = args.levels.split(',');
    detectCombinations(projectKeys)

    promises.push(uniqueProjectsWithSearch(projectKeys,projectKeyPath));
    promises.push(uniqueProjectsWithCombinationSearch(projectKeys,projectKeyPath));
    promises.push(uniques(projectKeys,projectKeyPath));
    promises.push(levels(projectKeys,projectKeyPath,LEVELS));
    promises.push(features(projectKeys,projectKeyPath));
    promises.push(searchProjectPatterns(projectKeys,projectKeyPath));
    promises.push(uniqueProjectKeysWithPertPlates(projectKeys,projectKeyPath));

    const p = await Promise.all(promises);
    return "done";
}
const parser = new ArgumentParser({
    description: 'Argparse example'
  });
   
parser.add_argument('-f', '--compound_key_file', { required: true, help: 'Compound key file' });
parser.add_argument('-l', '--levels', { default: LEVELS.join(','), help: 'Comma separated list of Levels' });

const args=parser.parse_args()
console.log(args.levels)

// const allARGS = process.argv;
// if(allARGS.length != 3){
//     console.log("node projectKeys <compound_key_json>");
//     process.exit(1);
// }

const projectKey = args.compound_key_file;

const p = doAll(projectKey,args);

p.then(function(data){
    console.log(data);
    process.exit(0);
}).catch(function (err) {
    console.log(err);
    process.exit(1);
});




