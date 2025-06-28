const _ = require("underscore");
const fetch = require("node-fetch");

/**
 *
 * Sync to analysis.clue.io and then link roles in clue
 *
 */
class Analysis2clue {
    /**
     *
     * @param apiKey - The API Key
     * @param apiURL - The API URL
     * @param buildID - The ID of teh CLUE build
     * @param projectName - the name of the project to be used as folder name on analysis.clue.io
     * @param indexFile - full path to the index.html file
     * @param roleId - CLUE role to assign access, comma-separated list <string>
     * @param is_review - Is report staged for review?
     */
    constructor(apiKey, apiURL, buildID, projectName, indexFile, roleId = 'cmap_core', approved = false) {
        this.apiKey = apiKey;
        this.apiURL = apiURL;
        this.buildID = buildID;
        this.indexFile = indexFile;
        this.roleId = roleId;
        this.roles = _.uniq(_.compact(this.roleId.split(",")))
        this.approved = approved;
        this.projectName = projectName.replace(/_/g, " ");
        this.postData = {
            "name": this.projectName,
            "description": this.projectName,
            "url": this.indexFile,
            "status": "APPROVED",
            "created_by": "MTS"
        }
        if (!this.approved) {
            this.projectName = "REVIEW--" + this.projectName
            this.postData.name = this.projectName
            this.postData.status = "NEEDS-REVIEW"
        }

        this.postURL = this.apiURL + "/api/data/" + buildID + "/external_analysis";
        console.log("within Analysis2clue, roleID:", this.roleId)
        console.log("within Analysis2clue, approved:", this.approved)
        console.log("Adding to see that this is a new comment")
    }

    /**
     *
     * Check if the resource already exists in clue
     * @param projectNameWithBuild
     * @return {Promise<*|*[]>}
     */
    async resourceExists(projectNameWithBuild) {
        const self = this;
        const options = {
            method: 'GET',
            headers: {
                'user_key': self.apiKey
            }
        };
        const whereClause = {
            where: {"or": [{"name": projectNameWithBuild}, {"url": self.indexFile}]},
            include: ["role"]
        };
        const resourceExistsURL = this.apiURL + "/api/preliminary-analysis?filter=" + JSON.stringify(whereClause);
        console.log("resourceExistsURL", resourceExistsURL)

        const response = await fetch(resourceExistsURL, options);
        if (response.status === 404) {
            return []
        }
        //check  if it exist before you do anything
        const respJSON = await response.json();
        return respJSON;
    }

    /**
     *
     * @param message
     * @param url
     * @param method
     * @returns {Promise<Response>}
     *
     */
    async postMethodAPI(message, url, method) {
        const fetch = require("node-fetch");
        const self = this;
        const payload = JSON.stringify(message);
        const options = {
            method: method,
            body: payload,
            headers: {
                "Content-Type": "application/json",
                'Content-Length': Buffer.byteLength(payload),
                "user_key": self.apiKey
            }
        };
        return await fetch(url, options);
    }

    static arrayEquals(a, b) {
        return Array.isArray(a) &&
            Array.isArray(b) &&
            a.length === b.length &&
            a.every((val, index) => val === b[index]);
    }

    async getBuildNameFromID() {
        const self = this;
        const buildURL = self.apiURL + "/api/data/" + self.buildID;
        const options = {
            method: 'GET',
            headers: {
                'user_key': self.apiKey
            }
        };
        console.log("getBuildNameFromID", buildURL);
        const resp = await fetch(buildURL, options)
        if (resp.ok && resp.status < 300) {
            const data = await resp.json();
            return data.name
        }
    }

    /**
     *
     * Register resource in CLUE
     *
     * @returns {Promise<{id: *}>}
     *
     */
    async registerInCLUE() {
        const _ = require("underscore")
        const self = this;
        console.log("registerInCLUE")
        const buildName = await self.getBuildNameFromID()
        console.log("After registerInCLUE")
        const projectNameWithBuild = self.projectName + " (" + buildName + ")"
        console.log("Project Name with Build: ", projectNameWithBuild)
        //check if resource exists in API before you post using url or name
        const response = await self.resourceExists(projectNameWithBuild);
        const matchingurlsPAs = _.filter(response,
            function (prelim_analysis) {
                return prelim_analysis.url === self.indexFile
            })

        const correctPA = _.filter(matchingurlsPAs,
            function (prelim_analysis) {
                return prelim_analysis.name === self.projectName
            })

        if (correctPA.length > 0) {
            // associate PA
            await self.confirmBuildAssociation(self.buildID, correctPA[0].id)

            const existingReport_roles = _.pluck(correctPA[0].role, 'role_id');

            if (Analysis2clue.arrayEquals(existingReport_roles.sort(), self.roles.sort())) {
                //x_project_id expects uppercase with underscore
                return {ignore: true};
            }
            return {ignore: false, id: correctPA[0].id}
        }

        const correctPAwithbuildname = _.filter(matchingurlsPAs,
            function (prelim_analysis) {
                return prelim_analysis.name === projectNameWithBuild
            })

        if (correctPAwithbuildname.length > 0) {
            // associate PA
            await self.confirmBuildAssociation(self.buildID, correctPAwithbuildname[0].id)

            const existingReport_roles = _.pluck(correctPAwithbuildname[0].role, 'role_id');

            if (Analysis2clue.arrayEquals(existingReport_roles.sort(), self.roles.sort())) {
                //x_project_id expects uppercase with underscore
                return {ignore: true};
            }
            return {ignore: false, id: correctPAwithbuildname[0].id}
        }
        // create a PA with a name + build
        self.postData.name = projectNameWithBuild
        const resp = await self.postMethodAPI(self.postData, self.postURL, "POST");
        const data = await resp.json();
        if (resp.ok && resp.status < 300) {
            return {ignore: false, id: data.id};
        }
        return {ignore: true};
    }

    /**
     *
     * @param prelim_analysisID - The ID to associate the preliminary analysis to cmap_core
     */
    async associateAnalysis2Role(prelim_analysisID) {
        const self = this;
        console.log("Roles to associate:", self.roles)
        const promises = [];

        // Clear previous roles
        for (const role of self.roles) {
            const url = self.apiURL + "/api/preliminary-analysis/" + prelim_analysisID + "/role/rel/" + role;
            console.log("role-assignment url:", url)
            promises.push(self.postMethodAPI({}, url, "PUT"));
        }
        try {
            const resp = await Promise.all(promises)
            return {success: "success"};
        } catch (e) {
            console.log(e)
            return {failure: "failure"};
        }
    }

    async confirmBuildAssociation(buildID, prelim_analysisID) {
        // check for relation
        // if relation does not exist
        // make relation
        const self = this;
        const buildExtAnalysisURL = this.apiURL + "/api/data/" + buildID + "/external_analysis/";
        console.log("Checking association for build.", buildExtAnalysisURL)
        const options = {
            method: 'GET',
            headers: {
                'user_key': self.apiKey
            }
        };

        const responses = await fetch(buildExtAnalysisURL, options)

        if (responses.ok && responses.status === 200) {
            const linkedAnalyses = await responses.json()
            const matchingPrelim = _.filter(linkedAnalyses, prelim => {
                return prelim.id === prelim_analysisID
            })
            if (matchingPrelim.length > 0) {
                return;
            } else {
                const creationURL = this.apiURL + "/api/data/" + buildID + "/external_analysis/rel/" + prelim_analysisID;
                const resp = await self.postMethodAPI({}, creationURL, "PUT");
                const data = await resp.json();
            }
        }
    }

    /**
     *
     * Start the processing
     * @returns {Promise<string>}
     *
     */
    async start() {
        const self = this;
        try {
            const resp = await self.registerInCLUE();
            if (!resp.ignore && resp.id) {
                console.log("associating roles")
                await self.associateAnalysis2Role(resp.id);
            }
        } catch (e) {
            console.log(e)
        }
        return "done";
    }


}


module.exports = Analysis2clue;
