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
        this.is_review = approved;
        this.projectName = projectName.replace(/_/g, " ");
        this.postData = {
            "name": this.projectName,
            "description": this.projectName,
            "url": this.indexFile,
            "status": "APPROVED",
            "created_by": "MTS"
        };

        if (!this.approved){
            this.projectName =  "REVIEW--" + this.projectName
            this.postData.name = this.projectName
            this.postData.status = "REVIEW"
        }

        const whereClause = {where:{"name": this.projectName}};
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

    /**
     *
     * Register resource in CLUE
     *
     * @returns {Promise<{id: *}>}
     *
     */
    async registerInCLUE() {
        const self = this;
        //check if resource exists in API before you post
        const response = await self.resourceExists();

        if (response.length > 0) {
            // if (self.indexFile === response[0].url) {
            console.log(self.projectName + " already exists");
            return {ignore: true};
            // }
        }
        //     const payload = {
        //         "url": self.indexFile
        //     }
        //
        //     console.log('payload:', payload)
        //     const prelim_analysisID = response[0].id
        //     console.log("analysis id", prelim_analysisID)
        //     const resp = await self.postMethodAPI(payload, self.postURL+"/" + prelim_analysisID, "PUT");
        //     const data = await resp.json();
        //
        //     console.log("DATA:", data)
        //     if (resp.ok && resp.status < 300) {
        //         return {ignore: false, id: data.id};
        //     }
        // }

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
        const roles = self.roleId.split(",")
        console.log("Roles to associate:", roles)
        const promises = [];

        const deleteURL = self.apiURL + "/api/preliminary-analysis/" + prelim_analysisID + "/role"
        await self.postMethodAPI({}, deleteURL, "DELETE")
        for (const role in roles){
            const url = self.apiURL + "/api/preliminary-analysis/" + prelim_analysisID + "/role/rel/" + role;
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
