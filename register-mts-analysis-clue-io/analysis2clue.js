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
    constructor(apiKey, apiURL, buildID, projectName, indexFile, roleId='cmap_core', approved=false) {
        this.apiKey = apiKey;
        this.apiURL = apiURL;
        this.indexFile = indexFile;
        this.roleId = roleId;
        this.roles = this.roleId.split(",")
        this.approved = approved;
        this.projectName = projectName.replace(/_/g, " ");
        this.postData = {
            "name": this.projectName,
            "description": this.projectName,
            "url": this.indexFile,
            "status": "APPROVED",
            "created_by": "MTS"
        };

        console.log("within Analysis2clue, roleID:", this.roleId)
        console.log("within Analysis2clue, approved:", this.approved)
        if (!this.approved){
            this.projectName =  "REVIEW--" + this.projectName
            this.postData.name = this.projectName
            this.postData.status = "NEEDS-REVIEW"
        }

        const whereClause = {where:{"name": this.projectName}, include: ["role"]};
        this.resourceExistsURL = this.apiURL + "/api/preliminary-analysis?filter=" + JSON.stringify(whereClause);
        this.postURL = this.apiURL + "/api/data/" + buildID + "/external_analysis";
    }

    /**
     *
     * Check if the resource already exists in clue
     *
     * @returns {Promise<any>}
     */
    async resourceExists() {
        const fetch = require("node-fetch");
        const self = this;
        const options = {
            method: 'GET',
            headers: {
                'user_key': self.apiKey
            }
        };
        console.log("self.resourceExistsURL", self.resourceExistsURL)
        const response = await fetch(self.resourceExistsURL, options);
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

    static arrayEquals (a, b) {
    return Array.isArray(a) &&
        Array.isArray(b) &&
        a.length === b.length &&
        a.every((val, index) => val === b[index]);
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
        //check if resource exists in API before you post
        const response = await self.resourceExists();

        if (response.length > 0) {
            // if (self.indexFile === response[0].url) {
            console.log(self.projectName + " already exists");

            const existingReport_roles = _.pluck(response[0].role, 'role_id');

            if (Analysis2clue.arrayEquals(existingReport_roles.sort(), self.roles.sort())) {
                //x_project_id expects uppercase with underscore
                return {ignore: true};
            }
            return {ignore: false, id: response[0].id}
        }

        //If does not exist, create
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
        // const deleteURL = self.apiURL + "/api/preliminary-analysis/" + prelim_analysisID + "/role"
        // await self.postMethodAPI({}, deleteURL, "DELETE")
        for (const role of self.roles){
            const url = self.apiURL + "/api/preliminary-analysis/" + prelim_analysisID + "/role/rel/" + role;
            console.log("role-assignment url:", url)
            promises.push(self.postMethodAPI({}, url, "PUT"));
        }
        try {
            const resp = await Promise.all(promises)
            return {success: "success"};
        }catch(e){
            console.log(e)
            return {failure: "failure"};
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
            console.log("after if statement")
        }catch (e){
            console.log(e)
        }
        return "done";
    }
}



module.exports = Analysis2clue;
