var express = require('express');
const http = require('http');
var request = require('postman-request');
var bodyParser = require('body-parser');
var router = express.Router();
const path = require('path');
const fs = require('fs');
var _ = require('underscore');
var q = require('q');

// get the applications configuration
var config = require("../config.js");
// connect to the database
var pg = require('pg');

// create application/json parser
var jsonParser = bodyParser.json();

// create application/x-www-form-urlencoded parser
var urlencodedParser = bodyParser.urlencoded({ extended: false });

// AGRA MIS Integration model (tracks integration status)
var MIS_INTEGRATOR = resetIntegrator();

// global datasets
var MIS_GRANTS = {};
// current PMT activities
var PMT_ACTIVITIES = null;
// current PMT contacts
var PMT_CONTACTS = null;
// current PMT organizations
var PMT_ORGANIZATIONS = null;
// current PMT taxonomies
var PMT_TAXONOMIES = null;
// current PMT boundaries
var PMT_BOUNDARIES = null;
// Organisation Roles taxonomy
var PMT_ROLES = { "funding": 496, "implementing": 497, "accountable": 494 };
// loccation taxonomy values for National/Local
var LOCAL_NATIONAL = [{ "national": 1121 }, { "local": 1122 }];
// loccation taxonomy values for Geographic Precision
var GEO_PRECISION = [{ 0: 2009 }, { 1: 2004 }, { 2: 2003 }];
// Taxonomies to be assigend to ALL locations (edited)
var ALL_LOCATION_CLASSES = [1988, 1989, 1995];

// request the start of AGRA's MIS integration
router.post('/agra_mis_integration', jsonParser, function (req, res) {
    try {
        // validate instance_id
        var instance_id = req.body.instance_id;
        if (typeof instance_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an instance_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate user_id
        var user_id = req.body.user_id;
        if (typeof user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an user_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        MIS_INTEGRATOR = resetIntegrator();

        // set integrator variables for pg connections
        MIS_INTEGRATOR.instance_id = instance_id;
        MIS_INTEGRATOR.user_id = user_id;
        MIS_INTEGRATOR.pmt_id = pmtId;

        // json object returned with response
        var jsonResponse = null;

        // MIS API options
        var options = {
            hostname: 'indicata.synisys.com',
            port: 80,
            path: '/agra-amis-pmt/api/grants',
            method: 'GET',
            headers: {
                'Authorization': '9a7ad9b3-ad70-4636-ae28-57855cb9fab6'
            }
        };
        // confirm file downloaded is good via file size
        var downloadFailed = false;
        var file_path = path.join(__dirname, 'tmp/mis.json');
        var mis_file = fs.createWriteStream(file_path);

        http.get(options, function (response) {
            response.pipe(mis_file);
        }).on("error", function (err) {
            // report error
            jsonResponse = JSON.stringify({ "error": true, "message": "MIS API data download failed with error: " + err.message });
            res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(jsonResponse) });
            res.end(jsonResponse);
        });

        // on file closed, start integration
        mis_file.on('close', function () {
            // begin integration logic
            MIStoPMTIntegration();
            // report that the integration logic has begun
            jsonResponse = JSON.stringify({ "error": true, "message": "MIS API data download successfully. MIS integration process has started." });
            res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(jsonResponse) });
            res.end(jsonResponse);
        });


        // if (downloadFailed) {
        //     jsonResponse = JSON.stringify({ "error": true, "message": "MIS API data download failed." });
        //     res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(jsonResponse) });
        //     res.end(jsonResponse);
        // }

        // // begin integration logic
        // MIStoPMTIntegration();

        // // report that the integration logic has begun
        // jsonResponse = JSON.stringify({ "error": false, "message": "MIS API data downloaded successfully. MIS integration process has started." });
        // res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(jsonResponse) });
        // res.end(jsonResponse);

    }
    catch (ex) {
        console.log(ex);
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request the status of AGRA's MIS integration
router.post('/agra_mis_integration_status', jsonParser, function (req, res) {
    try {
        // consolidate repetative error messages
        var uniques = _.map(_.groupBy(MIS_INTEGRATOR.issues, function (doc) {
            return doc.error;
        }), function (grouped) {
            return grouped[0];
        });
        MIS_INTEGRATOR.issues = uniques;
        // console.log("MIS_INTEGRATOR: ", MIS_INTEGRATOR);
        // report that the integration status
        jsonResponse = JSON.stringify(MIS_INTEGRATOR);
        res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(jsonResponse) });
        res.end(jsonResponse);

    }
    catch (ex) {
        console.log(ex);
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

module.exports = router;

// -------------------------------------------------------
// MIS Integration Process: Base Functions
// -------------------------------------------------------

// MIS integration process
function MIStoPMTIntegration() {

    // update the itegration model
    MIS_INTEGRATOR.running = true;
    MIS_INTEGRATOR.step_message = "Collecting MIS & PMT Data";

    // step 1: load MIS Grants from API
    loadMISGrants()
        // step 2: load current PMT contacts (PMT_CONTACTS)
        .then(loadPMTContacts)
        // step 3: load current PMT organizations (PMT_ORGANIZATIONS)
        .then(loadPMTOrganizations)
        // step 4: load current PMT taxonomies (PMT_TAXONOMIES)
        .then(loadPMTTaxonomies)
        // step 5: load current PMT boundaries (PMT_BOUNDARIES)
        .then(loadPMTBoundaries)
        // step 6: load current PMT activities (PMT_ACTIVITIES)
        .then(loadPMTActivities)
        // step 7: process all organizations in the AGRA MIS system
        .then(processMISOrganizations)
        // step 8: process all contacts in the AGRA MIS system
        .then(processMISContacts)
        // step 9: process all grants in the AGRA MIS system
        .then(processMISGrants).then(function (value) {
            MIS_INTEGRATOR.step_message = "Integration Complete";
            // finished successfully
            MIS_INTEGRATOR.running = false;
        })
        .catch(function (error) {
            // interruped with errors
            MIS_INTEGRATOR.running = false;
            // set the error message for status check
            MIS_INTEGRATOR.error = "MIS Integration was interrupted. The following error was reported: " + error;
            console.log("MIStoPMTIntegration error: ", error);
        })
        .finally(function () {
            MIS_INTEGRATOR.step_message = "Integration Complete";
            // finished successfully
            MIS_INTEGRATOR.running = false;
        });
}

// step 1: load MIS Grants from API
function loadMISGrants() {
    // update integrator step
    MIS_INTEGRATOR.step = 1;

    var deferred = q.defer();

    var file_path = path.join(__dirname, 'tmp/mis.json');
    fs.readFile(file_path, 'utf8', function (err, data) {
        if (err) {
            // integration failed, reset
            MIS_INTEGRATOR = resetIntegrator();
            // set the error message for status check
            MIS_INTEGRATOR.error = "MIS Integration failed during the reading of the download JSON file, from the MIS API.";
            deferred.reject();
        }
        // assign all MIS grants
        MIS_GRANTS = JSON.parse(data);
        MIS_GRANTS = MIS_GRANTS["Grants"];
        // update integrator stats
        MIS_INTEGRATOR.stats.total = MIS_GRANTS.length;
        console.log("Step 1: MIS Grants Loaded ---------------------> ");
        deferred.resolve(MIS_GRANTS);
    });
    return deferred.promise;
}

// step 2: load current PMT contacts (PMT_CONTACTS)
function loadPMTContacts() {
    var deferred = q.defer();
    MIS_INTEGRATOR.step = 2;

    try {
        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // integration failed, reset
            MIS_INTEGRATOR = resetIntegrator();
            // set the error message for status check
            MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not configured.";
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // integration failed, reset
                MIS_INTEGRATOR = resetIntegrator();
                // set the error message for status check
                MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not reachable.";
                deferred.reject();
            }
            client.query('SELECT * FROM pmt_contacts()', function (err, result) {
                done();
                if (err) {
                    // integration failed, reset
                    MIS_INTEGRATOR = resetIntegrator();
                    // set the error message for status check
                    MIS_INTEGRATOR.error = "MIS Integration failed during the loading PMT resources.";
                    deferred.reject();
                }
                PMT_CONTACTS = result.rows;
                console.log("Step 1: PMT Contacts Loaded ---------------------> ");
                deferred.resolve(PMT_CONTACTS);
            });
        });
    }
    catch (ex) {
        // integration failed, reset
        MIS_INTEGRATOR = resetIntegrator();
        // set the error message for status check
        MIS_INTEGRATOR.error = "MIS Integration failed during the loading PMT resources.";
        deferred.reject();
    }
    return deferred.promise;
}

// step 3: load current PMT organizations (PMT_ORGANIZATIONS)
function loadPMTOrganizations() {
    var deferred = q.defer();
    MIS_INTEGRATOR.step = 3;

    try {
        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // integration failed, reset
            MIS_INTEGRATOR = resetIntegrator();
            // set the error message for status check
            MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not configured.";
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // integration failed, reset
                MIS_INTEGRATOR = resetIntegrator();
                // set the error message for status check
                MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not reachable.";
                deferred.reject();
            }
            client.query('SELECT * FROM pmt_orgs()', function (e, r) {
                done();
                if (e) {
                    deferred.reject();
                }
                PMT_ORGANIZATIONS = r.rows;
                console.log("Step 3: PMT Organizations Loaded ---------------------> ");
                deferred.resolve(PMT_ORGANIZATIONS);
            });
        });
    }
    catch (ex) {
        // integration failed, reset
        MIS_INTEGRATOR = resetIntegrator();
        // set the error message for status check
        MIS_INTEGRATOR.error = "MIS Integration failed during the loading PMT resources.";
        deferred.reject();
    }

    return deferred.promise;
}

// step 4: load current PMT taxonomies (PMT_TAXONOMIES)
function loadPMTTaxonomies() {
    var deferred = q.defer();
    MIS_INTEGRATOR.step = 4;

    try {
        var instance_id = MIS_INTEGRATOR.instance_id;
        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // integration failed, reset
            MIS_INTEGRATOR = resetIntegrator();
            // set the error message for status check
            MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not configured.";
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // integration failed, reset
                MIS_INTEGRATOR = resetIntegrator();
                // set the error message for status check
                MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not reachable.";
                deferred.reject();
            }
            client.query('SELECT * FROM _taxonomy_classifications', function (err, result) {
                done();
                if (err) {
                    deferred.reject();
                }
                PMT_TAXONOMIES = result.rows;
                console.log("Step 4: PMT Taxonomies Loaded ---------------------> ");
                deferred.resolve(PMT_TAXONOMIES);
            });
        });
    }
    catch (ex) {
        // integration failed, reset
        MIS_INTEGRATOR = resetIntegrator();
        // set the error message for status check
        MIS_INTEGRATOR.error = "MIS Integration failed during the loading PMT resources.";
        deferred.reject();
    }

    return deferred.promise;
}

// step 5: load current PMT boundaries (PMT_BOUNDARIES)
function loadPMTBoundaries() {
    var deferred = q.defer();
    MIS_INTEGRATOR.step = 5;

    try {
        var boundary_type = "gaul";
        var admin_levels = "0,1,2";
        var filter_features = ["Burkina Faso", "Benin", "Côte d'Ivoire", "Ethiopia", "Gambia", "Ghana", "Guinea", "Guinea-Bissau", "Kenya", "Liberia", "Malawi", "Mali", "Namibia",
            "Mozambique", "Niger", "Nigeria", "Rwanda", "Sierra Leone", "Senegal", "South Africa", "South Sudan", "Tanzania", "Togo", "Uganda", "Zambia", "Zimbabwe"].join(",");
        var data_group_ids = MIS_INTEGRATOR.data_group_id.toString();
        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // integration failed, reset
            MIS_INTEGRATOR = resetIntegrator();
            // set the error message for status check
            MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not configured.";
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // integration failed, reset
                MIS_INTEGRATOR = resetIntegrator();
                // set the error message for status check
                MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not reachable.";
                deferred.reject();
            }
            client.query('SELECT * FROM pmt_boundary_hierarchy($1,$2,$3,$4)', [boundary_type, admin_levels, filter_features, data_group_ids], function (err, result) {
                done();
                if (err) {
                    deferred.reject();
                }
                PMT_BOUNDARIES = result.rows[0].response;
                console.log("Step 5: PMT Boundaries Loaded ---------------------> ");
                deferred.resolve(PMT_BOUNDARIES);
            });
        });
    }
    catch (ex) {
        // integration failed, reset
        MIS_INTEGRATOR = resetIntegrator();
        // set the error message for status check
        MIS_INTEGRATOR.error = "MIS Integration failed during the loading PMT resources.";
        deferred.reject();
    }

    return deferred.promise;
}

// step 6: load current PMT activities (PMT_ACTIVITIES)
function loadPMTActivities() {
    var deferred = q.defer();
    MIS_INTEGRATOR.step = 6;

    try {
        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // integration failed, reset
            MIS_INTEGRATOR = resetIntegrator();
            // set the error message for status check
            MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not configured.";
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // integration failed, reset
                MIS_INTEGRATOR = resetIntegrator();
                // set the error message for status check
                MIS_INTEGRATOR.error = "MIS Integration failed PMT database is not reachable.";
                deferred.reject();
            }
            var data_group_ids = MIS_INTEGRATOR.data_group_id.toString();
            var only_active = true;
            client.query('SELECT * FROM pmt_activities_all($1, $2)', [data_group_ids, only_active], function (err, result) {
                done();
                if (err) {
                    deferred.reject();
                }
                PMT_ACTIVITIES = result.rows;
                MIS_INTEGRATOR.pmt.total = PMT_ACTIVITIES.length;
                console.log("Step 6: PMT Activities Loaded ---------------------> ");
                deferred.resolve(PMT_ACTIVITIES);
            });
        });
    }
    catch (ex) {
        // integration failed, reset
        MIS_INTEGRATOR = resetIntegrator();
        // set the error message for status check
        MIS_INTEGRATOR.error = "MIS Integration failed during the loading PMT resources.";
        deferred.reject();
    }

    return deferred.promise;
}

// step 7: process all organizations in the AGRA MIS system
function processMISOrganizations() {
    var deferred = q.defer();
    MIS_INTEGRATOR.step = 7;
    MIS_INTEGRATOR.step_message = "Integrating MIS data into PMT";

    try {
        var organizations = [];
        var create_organization_prommises = [];
        // loop through the grants and determine what to do with them
        _.each(MIS_GRANTS, function (grant) {
            if (grant["Funding Organization"].length > 0) {
                organizations = organizations.length === 0 ? organizations = grant["Funding Organization"] :
                    _.uniq(_.union(organizations, grant["Funding Organization"]), false, function (item, key, a) { return item["Organization Name"]; });
            }
            if (grant["Implementing Organization"].length > 0) {
                organizations = organizations.length === 0 ? organizations = grant["Implementing Organization"] :
                    _.uniq(_.union(organizations, grant["Implementing Organization"]), false, function (item, key, a) { return item["Organization Name"]; });
            }
            if (grant["Accountable Organization"]) {
                organizations.push(grant["Accountable Organization"]);
                organizations = _.uniq(organizations, function (item, key, a) { return item["Organization Name"]; });
            }
        });
        // loop through unique organizations and create them in PMT
        _.each(organizations, function (organization) {
            var name = organization["Organization Name"] ? organization["Organization Name"].toLowerCase().trim() : null;
            if (name) {
                var org = _.find(PMT_ORGANIZATIONS, function (o) {
                    var a_name = o.response._label ? o.response._label.toLowerCase().trim() : null;
                    var a_label = o.response._name ? o.response._name.toLowerCase().trim() : null;
                    return a_name === name || a_label === name;
                });
                // can't find organization in PMT, create new organization
                if (!org) {
                    MIS_INTEGRATOR.pmt.new_orgs++;
                    create_organization_prommises.push(newOrganization(organization));
                }
            }
        });
        console.log("Step 7: Load MIS New Organizations ---------------------> ");
        console.log("Step 7: MIS listing of organizations: ", organizations);
        if (create_organization_prommises.length > 0) {
            q.allSettled(create_organization_prommises).then(function (results) {
                results.forEach(function (result) {
                    if (result.state === "fulfilled") {
                    } else {
                        // add issue to report
                        MIS_INTEGRATOR.issues.push({
                            "error": "new organization in pmt",
                            "message": result.reason,
                            "value": result
                        });
                    }
                });
                deferred.resolve(results);
            });
        }
        else {
            MIS_INTEGRATOR.pmt.new_orgs = 0;
            deferred.resolve();
        }

    }
    catch (ex) {
        // interruped with errors
        MIS_INTEGRATOR.running = false;
        // set the error message for status check
        MIS_INTEGRATOR.error = "MIS Integration failed unexpectedly. Reported error: " + ex.message;
        deferred.reject();
    }

    return deferred.promise;
}

// step 8: process all contacts in the AGRA MIS system
function processMISContacts() {
    var deferred = q.defer();
    MIS_INTEGRATOR.step = 8;

    try {
        var contacts = [];
        var create_contact_prommises = [];
        // loop through the grants and determine what to do with them
        _.each(MIS_GRANTS, function (grant) {
            if (grant["Contact"]) {
                contacts.push(grant["Contact"]);
                contacts = _.uniq(contacts, function (item, key, a) { return item["Name"]; });
            }
        });
        // loop through unique contacts and create them in PMT
        _.each(contacts, function (contact) {
            var first_name = firstName(contact["Name"]);
            var last_name = lastName(contact["Name"]);
            var person = _.find(PMT_CONTACTS, function (c) {
                var a_last_name = c.response._last_name ? c.response._last_name.toLowerCase().trim() : null;
                var a_first_name = c.response._first_name ? c.response._first_name.toLowerCase().trim() : null;
                return a_first_name === first_name.toLowerCase().trim() && a_last_name === last_name.toLowerCase().trim();
            });
            if (!person) {
                MIS_INTEGRATOR.pmt.new_contacts++;
                create_contact_prommises.push(newContact(contact));
            }
        });
        console.log("Step 8: Load MIS New Contact ---------------------> ");
        console.log("8        MIS listing of contacts: ", contacts);
        var ids = [];
        if (create_contact_prommises.length > 0) {
            q.allSettled(create_contact_prommises).then(function (results) {
                results.forEach(function (result) {
                    if (result.state === "fulfilled") {
                        ids.push(result.value.id);
                    }
                });
                deferred.resolve(results);
            });
        }
        else {
            MIS_INTEGRATOR.pmt.new_contacts = 0;
            deferred.resolve();
        }

    }
    catch (ex) {
        // interruped with errors
        MIS_INTEGRATOR.running = false;
        // set the error message for status check
        MIS_INTEGRATOR.error = "MIS Integration failed unexpectedly. Reported error: " + ex.message;
        deferred.reject();
    }

    return deferred.promise;
}

// step 9: process all grants in the AGRA MIS system
function processMISGrants() {
    var deferred = q.defer();
    MIS_INTEGRATOR.step = 9;

    try {
        var grant_promises = [];
        // loop through the grants and determine what to do with them
        _.each(MIS_GRANTS, function (grant) {
            var pmt_activity = _.find(PMT_ACTIVITIES, function (a) { return a.response._iati_identifier === grant["Activity"]["IATI Identifier"]; })
            // grant exists in PMT
            if (pmt_activity) {
                MIS_INTEGRATOR.stats.matched++;
                grant_promises.push(matchedMISGrant(grant, pmt_activity));
            }
            // grant does not exists in PMT
            else {
                MIS_INTEGRATOR.stats.new++;
                grant_promises.push(newMISGrant(grant));
            }
        });
        // loop through pmt activities for unmatched grants (not found in MIS)
        _.each(PMT_ACTIVITIES, function (a) {
            var mis_grant = _.find(MIS_GRANTS, function (g) { return g["Activity"]["IATI Identifier"] === a.response._iati_identifier.trim(); })
            if (!mis_grant) {
                MIS_INTEGRATOR.stats.missing++;
                // add activitys to delete
                MIS_INTEGRATOR.pmt.delete_activities.push(a.response);
            }
        });

        if (MIS_INTEGRATOR.pmt.delete_activities.length > 0) {
            grant_promises.push(missingMISGrants(MIS_INTEGRATOR.pmt.delete_activities));
        }

        console.log("Step 9: Process MIS Grants ---------------------> ");
        // step 9: load all new grants from MIS into PMT
        if (grant_promises.length > 0) {
            q.allSettled(grant_promises).then(function (results) {
                deferred.resolve(results);
            });
        }
        else {
            deferred.resolve();
        }
    }
    catch (ex) {
        // interruped with errors
        MIS_INTEGRATOR.running = false;
        // set the error message for status check
        MIS_INTEGRATOR.error = "MIS Integration failed unexpectedly. Reported error: " + ex.message;
        deferred.reject();
    }

    return deferred.promise;
}

// -------------------------------------------------------
// MIS Integration Process: MIS Data Processing Functions
// -------------------------------------------------------

// a new MIS grant: add activity to PMT
function newMISGrant(grant) {
    var deferred = q.defer();
    var process_grant_promises = [];
    try {
        // add new activity
        editActivity(grant, null).then(function (response) {
            // add contact information
            if (response.id && grant["Contact"]) {
                process_grant_promises.push(processGrantContact(response.id, grant["Contact"], 'add'));
            }
            // add funding organization information
            if (response.id && grant["Funding Organization"].length > 0) {
                process_grant_promises.push(processGrantParticipants(response.id, grant["Funding Organization"], PMT_ROLES.funding));
            }
            // add implementing organization information
            if (response.id && grant["Implementing Organization"].length > 0) {
                process_grant_promises.push(processGrantParticipants(response.id, grant["Implementing Organization"], PMT_ROLES.implementing));
            }
            // add accountable organization information
            if (response.id && grant["Accountable Organization"]) {
                process_grant_promises.push(processGrantParticipants(response.id, grant["Accountable Organization"], PMT_ROLES.accountable));
            }
            // add financial information
            if (response.id && grant["Financial"]) {
                process_grant_promises.push(processGrantFinancials(response.id, grant, grant["Financial"], null));
            }
            // add activity taxonomy information
            if (response.id && grant["Activity"]) {
                process_grant_promises.push(processGrantTaxonomies(response.id, grant["Activity"], 'add'));
            }
            // add activity location information
            if (response.id && grant["Location"]) {
                process_grant_promises.push(processGrantLocations(response.id, grant["Location"], null));
            }
            // process grant promises if any
            if (process_grant_promises.length > 0) {
                q.allSettled(process_grant_promises).then(function (results) {
                    deferred.resolve();
                });
            }
            else {
                deferred.resolve();
            }

        }).done();
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "add new grant to pmt",
            "message": ex.message,
            "value": grant["Activity"]["IATI Identifier"]
        });
        deferred.reject();
    }

    return deferred.promise;
}

// a matched MIS grant: update activity in PMT
function matchedMISGrant(grant, activity) {
    var deferred = q.defer();
    var process_grant_promises = [];
    try {
        var changes = {
            activity: false,
            taxonomy: false,
            contact: false,
            funding: false,
            implementing: false,
            accountable: false,
            financial: false,
            location: false
        };
        var activityElements = _.pairs(activity.response);
        // determine if there are any changes to make
        _.each(activityElements, function (activityElement) {
            switch (activityElement[0]) {
                case "_title":
                    if (activityElement[1] !== grant["Activity"]["IATI Identifier"] + ": " + grant["Activity"]["Title"]) {
                        changes.activity = true;
                    }
                    break;
                case "_description":
                    var pmtD = activityElement[1] ? activityElement[1] : null;
                    var misD = grant["Activity"]["Description"] !== "" && grant["Activity"]["Description"] !== null ? grant["Activity"]["Description"] : null;
                    if (pmtD && misD && pmtD !== misD) {
                        changes.activity = true;
                    }
                    break;
                case "_start_date":
                    if (activityElement[1] !== grant["Activity"]["Start Date"]) {
                        changes.activity = true;
                    }
                    break;
                case "_end_date":
                    if (activityElement[1] !== grant["Activity"]["End Date"]) {
                        changes.activity = true;
                    }
                    break;
                case "_url":
                    if (activityElement[1] !== grant["Activity"]["URL"]) {
                        changes.activity = true;
                    }
                    break;
                case "c":
                    var classificationIds = validateTaxonomies(_.pairs(grant["Activity"]));
                    // only update taxonomies in PMT if MIS has values
                    if (classificationIds.length > 0) {
                        if (_.difference(activityElement[1], classificationIds) > 0) {
                            changes.taxonomy = true;
                        }
                    }
                    break;
                case "contacts":
                    // only update PMT if MIS has a value
                    if (grant["Contact"] !== null) {
                        var first_name = firstName(grant["Contact"]["Name"]);
                        var last_name = lastName(grant["Contact"]["Name"]);
                        var name = first_name + " " + last_name;
                        // PMT has data, check to see if MIS=PMT
                        if (activityElement[1] !== null) {
                            _.each(activityElement[1], function (contact) {
                                if (contact.n !== name) {
                                    changes.contact = true;
                                }
                            });
                        }
                        // PMT doesn't have data
                        else {
                            changes.contact = true;
                        }
                    }
                    break;
                case "financials":
                    // only update PMT if MIS has a value
                    if (grant["Financial"].length > 0) {
                        var sumPMT = 0;
                        var sumMIS = 0;
                        // PMT has data, check to see if MIS=PMT
                        if (activityElement[1] !== null) {
                            _.each(activityElement[1], function (f) {
                                sumPMT = sumPMT + f.a;
                            });
                            _.each(grant["Financial"], function (g) {
                                sumMIS = sumMIS + parseFloat(g["Amount"]);
                            });
                            if (sumMIS !== 0 && sumPMT !== sumMIS) {
                                changes.financial = true;
                            }
                        }
                        // PMT doesn't have data
                        else {
                            changes.financial = true;
                        }
                    }
                    break;
                case "implementing":
                    // only update PMT if MIS has a value
                    if (grant["Implementing Organization"].length > 0) {
                        var MISFunders = [];
                        _.each(grant["Implementing Organization"], function (grantFunder) {
                            MISFunders.push(grantFunder["Organization Name"] ? grantFunder["Organization Name"].toLowerCase().trim() : null);
                        });
                        if (MISFunders.length > 0) {
                            var PMTFunders = _.filter(activityElement[1], function (o) {
                                var a_name = o._label ? o._label.toLowerCase().trim() : null;
                                var a_label = o._name ? o._name.toLowerCase().trim() : null;
                                return _.contains(MISFunders, a_name) || _.contains(MISFunders, a_label);
                            });
                            if (PMTFunders.length !== MISFunders.length) {
                                changes.implementing = true;
                            }
                        }
                    }
                    break;
                case "funding":
                    // only update PMT if MIS has a value
                    if (grant["Funding Organization"].length > 0) {
                        var MISFunders = [];
                        _.each(grant["Funding Organization"], function (grantFunder) {
                            MISFunders.push(grantFunder["Organization Name"] ? grantFunder["Organization Name"].toLowerCase().trim() : null);
                        });
                        if (MISFunders.length > 0) {
                            var PMTFunders = _.filter(activityElement[1], function (o) {
                                var a_name = o._label ? o._label.toLowerCase().trim() : null;
                                var a_label = o._name ? o._name.toLowerCase().trim() : null;
                                return _.contains(MISFunders, a_name) || _.contains(MISFunders, a_label);
                            });
                            if (PMTFunders.length !== MISFunders.length) {
                                changes.funding = true;
                            }
                        }
                    }
                    break;
                case "accountable":
                    // only update PMT if MIS has a value
                    if (grant["Accountable Organization"] != null) {
                        var MISFunders = [];
                        MISFunders.push(grant["Accountable Organization"]["Organization Name"] ? grant["Accountable Organization"]["Organization Name"].toLowerCase().trim() : null);

                        if (MISFunders.length > 0) {
                            var PMTFunders = _.filter(activityElement[1], function (o) {
                                var a_name = o._label ? o._label.toLowerCase().trim() : null;
                                var a_label = o._name ? o._name.toLowerCase().trim() : null;
                                return _.contains(MISFunders, a_name) || _.contains(MISFunders, a_label);
                            });
                            if (PMTFunders.length !== MISFunders.length) {
                                changes.accountable = true;
                            }
                        }
                    }
                    break;
                case "locations":
                    // only update PMT if MIS has a value
                    if (grant["Location"].length > 0) {
                        var misLevels =
                        {
                            a0: { names: [] },
                            a1: { names: [] },
                            a2: { names: [] }
                        };
                        _.each(grant["Location"], function (country) {
                            if (country["Country"] !== null) {
                                misLevels.a0.names.push(country["Country"]);
                                _.each(country["Administrative Levels"], function (levels) {
                                    if (levels["Administrative Level 1"] !== null) {
                                        misLevels.a1.names.push(levels["Administrative Level 1"]);
                                    }
                                    if (levels["Administrative Level 2"].length > 0) {
                                        misLevels.a2.names = _.union(misLevels.a2.names, levels["Administrative Level 2"]);
                                    }
                                });
                            }
                        });
                        var pmtLevels =
                        {
                            a0: { names: [] },
                            a1: { names: [] },
                            a2: { names: [] }
                        };
                        var admin0 = _.filter(activityElement[1], function (l) { return l._admin_level === 0; });
                        var admin1 = _.filter(activityElement[1], function (l) { return l._admin_level === 1; });
                        var admin2 = _.filter(activityElement[1], function (l) { return l._admin_level === 2; });
                        pmtLevels.a0.names = _.pluck(admin0, '_admin0');
                        pmtLevels.a1.names = _.pluck(admin1, '_admin1');
                        pmtLevels.a2.names = _.pluck(admin2, '_admin2');

                        // MIS has level 2 
                        if (misLevels.a2.names.length > 0) {
                            // PMT has level 2
                            if (pmtLevels.a2.names.length > 0) {
                                if (_.difference(misLevels.a2.names, pmtLevels.a2.names).length > 0) {
                                    changes.location = true;
                                }
                            }
                            else {
                                changes.location = true;
                            }
                        }
                        // MIS has level 1
                        else if (misLevels.a1.names.length > 0 && pmtLevels.a2.names.length === 0) {
                            // PMT has level 1
                            if (pmtLevels.a1.names.length > 0) {
                                if (_.difference(misLevels.a1.names, pmtLevels.a1.names).length > 0) {
                                    changes.location = true;
                                }
                            }
                            else {
                                changes.location = true;
                            }
                        }
                        else {
                            // MIS has level 0
                            if (misLevels.a0.names.length > 0 && pmtLevels.a2.names.length === 0 && pmtLevels.a1.names.length === 0) {
                                // PMT has level 0
                                if (pmtLevels.a0.names.length > 0) {
                                    if (_.difference(misLevels.a0.names, pmtLevels.a0.names).length > 0) {
                                        changes.location = true;
                                    }
                                }
                            }
                        }
                    }
                    break;
            }
        });

        var chgCt = _.filter(_.pairs(changes), function (c) { return c[1]; }).length;
        if (chgCt > 0) {
            MIS_INTEGRATOR.stats.changed++;
        }
        // submit requested activity changes
        if (changes.activity) {
            process_grant_promises.push(editActivity(grant, activity.response.id));
        }
        // submit requested contact changes
        if (changes.contact) {
            if (grant["Contact"] !== null) {
                process_grant_promises.push(processGrantContact(activity.response.id, grant["Contact"], 'replace'));
            }
        }
        // submit requested funder changes
        if (changes.funding) {
            process_grant_promises.push(processGrantParticipants(activity.response.id, grant["Funding Organization"], PMT_ROLES.funding));
        }
        // submit requested implementing changes
        if (changes.implementing) {
            process_grant_promises.push(processGrantParticipants(activity.response.id, grant["Implementing Organization"], PMT_ROLES.implementing));
        }
        // submit requested accountable changes
        if (changes.accountable) {
            process_grant_promises.push(processGrantParticipants(activity.response.id, grant["Accountable Organization"], PMT_ROLES.accountable));
        }
        // submit requested financial changes
        if (changes.financial) {
            if (grant["Financial"].length > 0) {
                var fids = _.pluck(activity.response.financials, 'id');
                process_grant_promises.push(processGrantFinancials(activity.response.id, grant, grant["Financial"], fids));
            }
        }
        // submit requested activity taxonomy changes
        if (changes.taxonomy) {
            process_grant_promises.push(processGrantTaxonomies(activity.response.id, grant["Activity"], 'replace'));
        }
        // submit requested location changes
        if (changes.location) {
            var lids = _.pluck(activity.response.locations, 'id');
            process_grant_promises.push(processGrantLocations(activity.response.id, grant["Location"], lids));
        }
        // process grant promises if any
        if (process_grant_promises.length > 0) {
            q.allSettled(process_grant_promises).then(function (results) {
                deferred.resolve();
            });
        }
        else {
            deferred.resolve();
        }
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "update matched grant to pmt",
            "message": ex.message,
            "value": grant["Activity"]["IATI Identifier"]
        });
        deferred.reject();
    }
    return deferred.promise;
}

// missing MIS grants: delete activities in PMT
function missingMISGrants(activities) {
    var deferred = q.defer();
    try {
        var activityIds = _.pluck(activities, 'id');
        if (activityIds.length > 0) {
            deleteActivities(activityIds).then(function (response) {
                deferred.resolve();
            }, function (ex) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "delete grants from pmt",
                    "message": ex.message,
                    "value": activityIds
                });
                deferred.reject();
            });
        }
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "delete grants from pmt",
            "message": ex.message,
            "value": activityIds
        });
        deferred.reject();
    }
    return deferred.promise;
}

// process a MIS Grant contact information
function processGrantContact(activityId, grantContact, action) {
    var deferred = q.defer();
    try {
        var new_grant_contract_promises = [];
        var first_name = firstName(grantContact["Name"]);
        var last_name = lastName(grantContact["Name"]);
        var contact = _.find(PMT_CONTACTS, function (c) {
            var a_last_name = c.response._last_name ? c.response._last_name.toLowerCase().trim() : null;
            var a_first_name = c.response._first_name ? c.response._first_name.toLowerCase().trim() : null;
            return a_first_name === first_name.toLowerCase().trim() && a_last_name === last_name.toLowerCase().trim();
        });
        if (contact) {
            if (action === 'add') {
                addContactToActivity(activityId, contact.response.id).then(function (result) {
                    deferred.resolve(results);
                }, function () {
                    MIS_INTEGRATOR.issues.push({
                        "error": "process grant contact for pmt",
                        "message": "contact was not connected to activity",
                        "value": grantContact["Name"]
                    });
                    deferred.reject();
                });
            }
            else {
                replaceContactToActivity(activityId, contact.response.id).then(function (result) {
                    deferred.resolve(results);
                }, function () {
                    MIS_INTEGRATOR.issues.push({
                        "error": "process grant contact for pmt",
                        "message": "contact was not connected to activity",
                        "value": grantContact["Name"]
                    });
                    deferred.reject();
                });
            }
        }
        else {
            // new contact should have been loaded on step 7
            // add issue to report
            MIS_INTEGRATOR.issues.push({
                "error": "process grant contact for pmt",
                "message": "new contact was not created in step 7",
                "value": grantContact["Name"]
            });
            deferred.reject();
        }
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "process grant contact for pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }

    return deferred.promise;
}

// process a MIS Grant funder information
function processGrantParticipants(activityId, grantParticipants, roleId) {
    var deferred = q.defer();
    try {
        var organization_ids = []; // all organization ids for funders
        var new_org_promises = []; // promises for new organization records
        // validate object or array
        if (grantParticipants.constructor === Array) {
            _.each(grantParticipants, function (grantParticipant) {
                var name = grantParticipant["Organization Name"] ? grantParticipant["Organization Name"].toLowerCase().trim() : null;
                if (name) {
                    var org = _.find(PMT_ORGANIZATIONS, function (o) {
                        var a_name = o.response._label ? o.response._label.toLowerCase().trim() : null;
                        var a_label = o.response._name ? o.response._name.toLowerCase().trim() : null;
                        return a_name === name || a_label === name;
                    });
                    if (org) {
                        // exists
                        organization_ids.push(org.response.id);
                    }
                    else {
                        // new org should have been loaded on step 6
                        // add issue to report
                        MIS_INTEGRATOR.issues.push({
                            "error": "process grant participants for pmt",
                            "message": "new organization was not created in step 6",
                            "value": grantParticipant["Organization Name"]
                        });
                        deferred.reject();
                    }
                }
            });
        }
        else {
            var name = grantParticipants["Organization Name"] ? grantParticipants["Organization Name"].toLowerCase().trim() : null;
            if (name) {
                var org = _.find(PMT_ORGANIZATIONS, function (o) {
                    var a_name = o.response._label ? o.response._label.toLowerCase().trim() : null;
                    var a_label = o.response._name ? o.response._name.toLowerCase().trim() : null;
                    return a_name === name || a_label === name;
                });
                if (org) {
                    // exists
                    organization_ids.push(org.response.id);
                }
                else {
                    // new org should have been loaded on step 6
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "process grant participants for pmt",
                        "message": "new organization was not created in step 6",
                        "value": grantParticipants["Organization Name"]
                    });
                    deferred.reject();
                }
            }
        }
        replaceAllParticipants(activityId, organization_ids, roleId).then(function (result) {
            deferred.resolve(results);
        }, function () {
            MIS_INTEGRATOR.issues.push({
                "error": "process grant participants for pmt",
                "message": "new organization was not created in step 6",
                "value": grantParticipant["Organization Name"]
            });
            deferred.reject();
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "process grant participants for pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }

    return deferred.promise;
}

// process a MIS Grant financial information
function processGrantFinancials(activityId, grant, grantFinancials, deleteIds) {
    var deferred = q.defer();
    try {
        var new_financial_promises = []; // promises for new organization records
        var organizationIds = validateOrganizations(grant["Funding Organization"]);
        var organizationId = organizationIds.length > 0 ? organizationIds[0] : null;
        _.each(grantFinancials, function (grantFinancial) {
            var amount = grantFinancial["Amount"] ? parseFloat(grantFinancial["Amount"]) : null;
            var classificationids = validateTaxonomies(_.pairs(grantFinancial));
            if (amount && amount !== 0) {
                new_financial_promises.push(editFinancial(activityId, organizationId, grant, grantFinancial, classificationids, null, false));
            }
        });
        _.each(deleteIds, function (fid) {
            if (fid) {
                new_financial_promises.push(editFinancial(activityId, null, grant, null, null, fid, true));
            }
        });
        if (new_financial_promises.length > 0) {
            q.allSettled(new_financial_promises).then(function (results) {
                deferred.resolve(results);
            });
        }
        else {
            deferred.resolve(true);
        }
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "process grant financials for pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }

    return deferred.promise;
}

// process a MIS Grant taxonomy information
function processGrantTaxonomies(activityId, grantActivity, action) {
    var deferred = q.defer();
    try {

        var classificationIds = validateTaxonomies(_.pairs(grantActivity));
        newActivityTaxonomy(activityId, classificationIds, action).then(function (result) {
            deferred.resolve(result);
        }, function () {
            MIS_INTEGRATOR.issues.push({
                "error": "process grant taxonomies for pmt",
                "message": "error creating activity taxonomy",
                "value": activityId
            });
            deferred.reject();
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "process grant taxonomies for pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// process a MIS Grant location information
function processGrantLocations(activityId, grantLocations, deleteIds) {
    var deferred = q.defer();
    try {
        var locations = []; // array of locations for grant
        var new_grant_location_promises = [];
        // location data model expected by PMT API function for locations
        var model = {
            boundary_id: null,
            feature_id: null,
            admin_level: null,
            admin0: null,
            admin1: null,
            admin2: null
        };
        // delete locations
        _.each(deleteIds, function (lid) {
            if (lid) {
                editLocation(activityId, null, lid, true);
            }
        });
        // loop through grant location array of objects
        _.each(grantLocations, function (grantLocation) {
            var location = _.extend(model);
            var admin0Feature = null;
            var admin1Feature = null;
            var admin2Feature = null;
            var admin0 = grantLocation["Country"];
            location.admin0 = admin0;
            var adminLevels = grantLocation["Administrative Levels"];
            // find admin0 feature
            if (admin0) {
                admin0Feature = _.find(PMT_BOUNDARIES.boundaries, function (a0) { return a0.n.toLowerCase() === admin0.toLowerCase(); });
            }
            // national level location
            if (adminLevels.length === 0 && admin0Feature) {
                location.admin_level = 0;
                if (admin0Feature) {
                    location.boundary_id = PMT_BOUNDARIES.b0;
                    location.feature_id = admin0Feature.id;
                    if (location.feature_id !== null && location.boundary_id !== null) {
                        //new_grant_location_promises.push(editLocation(activityId, location, null, false));
                        editLocation(activityId, location, null, false);
                    }
                }
            }
            // sub-national level location
            if (adminLevels.length > 0 && admin0Feature) {
                // loop through levels
                _.each(adminLevels, function (adminLevel) {
                    // admin 1 level location
                    var admin1 = adminLevel["Administrative Level 1"];
                    var admin2Levels = adminLevel["Administrative Level 2"];
                    // find admin1 feature
                    if (admin1) {
                        admin1Feature = _.find(admin0Feature.b, function (a1) { return a1.n.toLowerCase() === admin1.toLowerCase(); });
                    }
                    // admin 2 level locations
                    if (admin2Levels.length > 0 && admin1Feature) {
                        location.admin1 = admin1;
                        location.admin_level = 2;
                        _.each(admin2Levels, function (admin2Level) {
                            var admin2 = _.extend(location);
                            admin2.admin2 = admin2Level;
                            // find admin1 feature
                            if (admin2Level) {
                                admin2Feature = _.find(admin1Feature.b, function (a2) { return a2.n.toLowerCase() === admin2Level.toLowerCase(); });
                            }
                            if (admin2Feature) {
                                admin2.admin_level = 2;
                                admin2.boundary_id = PMT_BOUNDARIES.b2;
                                admin2.feature_id = admin2Feature.id;
                                if (admin2.feature_id !== null && admin2.boundary_id !== null) {
                                    //new_grant_location_promises.push(editLocation(activityId, admin2, null, false));
                                    editLocation(activityId, admin2, null, false);
                                }
                            }
                        });
                    }
                    // admin 1 level locations
                    if (admin2Levels.length === 0 && admin1Feature) {
                        if (admin1Feature) {
                            location.admin1 = admin1;
                            location.admin_level = 1;
                            location.boundary_id = PMT_BOUNDARIES.b1;
                            location.feature_id = admin1Feature.id;
                            if (location.feature_id !== null && location.boundary_id !== null) {
                                //new_grant_location_promises.push(editLocation(activityId, location, null, false));
                                editLocation(activityId, location, null, false);
                            }
                        }
                    }
                });
            }
        });
        // if (new_grant_location_promises.length > 0) {
        //     q.allSettled(new_grant_location_promises).then(function (results) {
        //         deferred.resolve(results);
        //     });
        // }
        // else {
        //     deferred.resolve();
        // }
        deferred.resolve();

    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "process grant locations for pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// get pmt organization ids for grant participant objects
function validateOrganizations(grantParticipants) {
    try {
        var organization_ids = []; // all organization ids for funders
        var new_org_promises = []; // promises for new organization records
        // validate object or array
        if (grantParticipants.constructor === Array) {
            _.each(grantParticipants, function (grantParticipant) {
                var name = grantParticipant["Organization Name"] ? grantParticipant["Organization Name"].toLowerCase().trim() : null;
                if (name) {
                    var org = _.find(PMT_ORGANIZATIONS, function (o) {
                        var a_name = o.response._label ? o.response._label.toLowerCase().trim() : null;
                        var a_label = o.response._name ? o.response._name.toLowerCase().trim() : null;
                        return a_name === name || a_label === name;
                    });
                    if (org) {
                        // exists
                        organization_ids.push(org.response.id);
                    }
                }
            });
        }
        else {
            var name = grantParticipants["Organization Name"] ? grantParticipants["Organization Name"].toLowerCase().trim() : null;
            if (name) {
                var org = _.find(PMT_ORGANIZATIONS, function (o) {
                    var a_name = o.response._label ? o.response._label.toLowerCase().trim() : null;
                    var a_label = o.response._name ? o.response._name.toLowerCase().trim() : null;
                    return a_name === name || a_label === name;
                });
                if (org) {
                    // exists
                    organization_ids.push(org.response.id);
                }
            }
        }
    }
    catch (ex) {
        console.log(ex);
    }

    return organization_ids;
}

// get classificationids for taxonomies:classification (key:value)
function validateTaxonomies(grantTaxonomies) {
    try {
        var classification_ids = []; // all classifications ids for taxonomies
        var taxonomies = [];

        _.each(grantTaxonomies, function (grantTaxonomy) {
            var key = grantTaxonomy[0];
            var value = grantTaxonomy[1];

            switch (key) {
                case "Finance Type Category":
                    taxonomies.push(["Finance Type (category)", value]);
                    break;
                case "Activity Scope":
                    if (value) {
                        taxonomies.push([key, value["Number"]]);
                    }
                    break;
                case "Client Custom Taxonomies":
                    _.each(value, function (v) {
                        var t = _.pairs(v);
                        taxonomies.push([t[0][0], t[0][1]]);
                    });
                    break;
                default:
                    taxonomies.push([key, value]);
                    break;
            }
        });

        _.each(taxonomies, function (grantTaxonomy) {
            var taxonomy = _.find(PMT_TAXONOMIES, function (t) {
                if (grantTaxonomy[1] !== null && grantTaxonomy[1] !== "") {
                    var t_code = t._code ? t._code.toLowerCase() : null;
                    var t_iati = t._iati_name ? t._iati_name.toLowerCase() : null;
                    return t.taxonomy.toLowerCase() === grantTaxonomy[0].toLowerCase() &&
                        (t.classification.toLowerCase() === grantTaxonomy[1].toLowerCase() ||
                            t_code === grantTaxonomy[1].toLowerCase() ||
                            t_iati === grantTaxonomy[1].toLowerCase());
                }
            });

            if (taxonomy) {
                classification_ids.push(taxonomy.classification_id);
            }
        });
    }
    catch (ex) {
        console.log(ex);
    }

    return classification_ids;
}

// -------------------------------------------------------
// MIS Integration Process: PMT Data Processing Functions
// -------------------------------------------------------

// create a new activity record in PMT
function editActivity(grant, activityId) {
    var deferred = q.defer();
    try {
        // database function parameters
        var instance_id = MIS_INTEGRATOR.instance_id;
        var user_id = MIS_INTEGRATOR.user_id;
        var data_group_id = MIS_INTEGRATOR.data_group_id;
        var activity_id = activityId || null;
        var delete_record = false;
        var key_value_data = {
            "_title": grant["Activity"]["IATI Identifier"] + ": " + grant["Activity"]["Title"],
            "_description": grant["Activity"]["Description"] || null,
            "_url": grant["Activity"]["URL"] || null,
            "_start_date": grant["Activity"]["Start Date"] || null,
            "_end_date": grant["Activity"]["End Date"] || null,
            "_iati_identifier": grant["Activity"]["IATI Identifier"]
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "new activity in pmt",
                    "message": err,
                    "value": grant["Activity"]["IATI Identifier"]
                });
                deferred.reject();
            }
            updatePMTCalls("activity", "calls");
            client.query('SELECT * FROM pmt_edit_activity($1,$2,$3,$4,$5,$6)', [instance_id, user_id, activity_id, data_group_id, key_value_data, delete_record], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new activity in pmt",
                        "message": err,
                        "value": grant["Activity"]["IATI Identifier"]
                    });
                    updatePMTCalls("activity", "fail");
                    deferred.reject();
                }
                if (result.rows[0].response.id) {
                    updatePMTCalls("activity", "pass");
                    deferred.resolve(result.rows[0].response);
                }
                else {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new activity in pmt",
                        "message": result.rows[0].response.message,
                        "value": grant["Activity"]["IATI Identifier"]
                    });
                    updatePMTCalls("activity", "fail");
                    deferred.reject();
                }
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "new activity in pmt",
            "message": ex.message,
            "value": grant["Activity"]["IATI Identifier"]
        });
        deferred.reject();
    }

    return deferred.promise;
}

// create a relationship between activity and contact
function deleteActivities(activityIds) {
    var deferred = q.defer();
    try {
        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "delete activity in pmt",
                    "message": err,
                    "value": activityIds
                });
                deferred.reject();
            }
            updatePMTCalls("activity", "calls", activityIds.length);
            client.query('SELECT * FROM pmt_purge_activities ($1)', [activityIds], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "delete activity in pmt",
                        "message": err,
                        "value": activityIds
                    });
                    updatePMTCalls("activity", "fail", activityIds.length);
                    deferred.reject();
                }
                updatePMTCalls("activity", "pass", activityIds.length);
                deferred.resolve(result);
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "delete activity in pmt",
            "message": ex.message,
            "value": activityIds
        });
        updatePMTCalls("activity", "fail", activityIds.length);
        deferred.reject();
    }
    return deferred.promise;
}

// create a new contact record in PMT
function newContact(grantContact) {
    var deferred = q.defer();

    try {
        // database function parameters
        var instance_id = MIS_INTEGRATOR.instance_id;
        var user_id = MIS_INTEGRATOR.user_id;
        var data_group_id = MIS_INTEGRATOR.data_group_id;
        var activity_id = null;
        var contact_id = null;
        var delete_record = false;
        var first_name = firstName(grantContact["Name"]);
        var last_name = lastName(grantContact["Name"]);
        var key_value_data = {
            "_first_name": firstName(grantContact["Name"]),
            "_last_name": lastName(grantContact["Name"]),
            "_title": grantContact["Title"] || null,
            "_email": grantContact["Email"] || null,
            "_address1": grantContact["Address"] || null,
            "_direct_phone": grantContact["Phone"] || null,
            "organization_id": null // TO DO: Look up organization id
        }
        // contact object to add to our global dataset PMT_CONTACTS
        var contact = {
            "response": {
                "id": 1231,
                "_first_name": firstName(grantContact["Name"]),
                "_last_name": lastName(grantContact["Name"]),
                "_title": grantContact["Title"] || null,
                "_email": grantContact["Email"] || null,
                "organization_id": null,
                "organization_name": null,
                "activities": null
            }
        };

        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "new contact in pmt",
                    "message": err,
                    "value": grantContact["Name"]
                });
                deferred.reject();
            }
            updatePMTCalls("contact", "calls");
            client.query('SELECT * FROM pmt_edit_contact($1,$2,$3,$4,$5,$6,$7)', [instance_id, user_id, activity_id, data_group_id, contact_id, key_value_data, delete_record], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new contact in pmt",
                        "message": err,
                        "value": grantContact["Name"]
                    });
                    updatePMTCalls("contact", "fail");
                    deferred.reject();
                }
                if (result.rows[0].response.id && result.rows[0].response.message.search("Internal Error") < 0) {
                    PMT_CONTACTS.push(contact);
                    updatePMTCalls("contact", "pass");
                    deferred.resolve(result.rows[0].response);
                }
                else {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new contact in pmt",
                        "message": result.rows[0].response.message,
                        "value": grantContact["Name"]
                    });
                    updatePMTCalls("contact", "fail");
                    deferred.reject();
                }
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "new contact in pmt",
            "message": ex.message,
            "value": grantContact["Name"]
        });
        deferred.reject();
    }

    return deferred.promise;
}

// create a new organization record in PMT
function newOrganization(grantOrganization) {
    var deferred = q.defer();
    try {
        // database function parameters
        var instance_id = MIS_INTEGRATOR.instance_id;
        var user_id = MIS_INTEGRATOR.user_id;
        var organization_id = null;
        var delete_record = false;
        var key_value_data = {
            "_name": grantOrganization["Organization Name"],
            "_label": grantOrganization["Organization Name"],
            "_address1": grantOrganization["Organization Address"] || null,
            "_url": grantOrganization["Organization Address"] || null
        }
        // organization object to add to our global dataset PMT_ORGANIZATIONS
        var organization =
        {
            "response": {
                "id": null,
                "_name": grantOrganization["Organization Name"],
                "_label": grantOrganization["Organization Name"],
                "_url": null
            }
        };

        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "new organization in pmt",
                    "message": err,
                    "value": grantOrganization["Organization Name"]
                });
                deferred.reject();
            }
            updatePMTCalls("organization", "calls");
            client.query('SELECT * FROM pmt_edit_organization($1,$2,$3,$4,$5)', [instance_id, user_id, organization_id, key_value_data, delete_record], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new organization in pmt",
                        "message": err,
                        "value": grantOrganization["Organization Name"]
                    });
                    updatePMTCalls("organization", "fail");
                    deferred.reject();
                }
                if (result.rows[0].response.id) {
                    PMT_ORGANIZATIONS.push(organization);
                    updatePMTCalls("organization", "pass");
                    deferred.resolve(result.rows[0].response);
                }
                else {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new organization in pmt",
                        "message": result.rows[0].response.message,
                        "value": grantOrganization["Organization Name"]
                    });
                    updatePMTCalls("organization", "fail");
                    deferred.reject();
                }

            });
        });

    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "new organization in pmt",
            "message": ex.message,
            "value": grantOrganization["Organization Name"]
        });
        deferred.reject();
    }
    return deferred.promise;
}

// edit a financial record in PMT
function editFinancial(activityId, organizationId, grant, grantFinancial, classificationIds, financialId, deleteRecord) {
    var deferred = q.defer();
    try {
        // database function parameters
        var instance_id = MIS_INTEGRATOR.instance_id;
        var user_id = MIS_INTEGRATOR.user_id;
        var activity_id = activityId;
        var financial_id = financialId || null;
        var delete_record = deleteRecord;
        var classification_ids = classificationIds;
        var key_value_data = null;
        if (grantFinancial) {
            key_value_data = {
                "provider_id": organizationId || null,
                "_amount": parseFloat(grantFinancial["Amount"]),
                "_start_date": grant["Activity"]["Start Date"] || null,
                "_end_date": grant["Activity"]["End Date"] || null
            };
        }


        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "new financial in pmt",
                    "message": err,
                    "value": activityId
                });
                deferred.reject();
            }
            updatePMTCalls("financial", "calls");
            client.query('SELECT * FROM pmt_edit_financial_with_taxonomy($1,$2,$3,$4,$5,$6,$7)', [instance_id, user_id, activity_id, financial_id, key_value_data, classification_ids, delete_record], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new financial in pmt",
                        "message": err,
                        "value": activityId
                    });
                    updatePMTCalls("financial", "fail");
                    deferred.reject();
                }
                if (result.rows[0].response.id && result.rows[0].response.message.search("Internal Error") < 0) {
                    updatePMTCalls("financial", "pass");
                    deferred.resolve(result.rows[0].response);
                }
                else {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new financial in pmt",
                        "message": result.rows[0].response.message,
                        "value": activityId
                    });
                    updatePMTCalls("financial", "fail");
                    deferred.reject();
                }
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "new financial in pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// create a new activity taxonomy record in PMT
function newActivityTaxonomy(activityId, classificationIds, action) {
    var deferred = q.defer();
    try {
        // database function parameters
        var instance_id = MIS_INTEGRATOR.instance_id;
        var user_id = MIS_INTEGRATOR.user_id;
        var activity_ids = activityId.toString();
        var classification_ids = classificationIds.join(',');
        var taxonomy_ids = null;
        var edit_action = action || 'add';

        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                MIS_INTEGRATOR.issues.push({
                    "error": "new activity taxonomy in pmt",
                    "message": err,
                    "value": activityId
                });
                deferred.reject();
            }
            updatePMTCalls("activity_taxonomy", "calls");
            client.query('SELECT * FROM pmt_edit_activity_taxonomy($1,$2,$3,$4,$5,$6)', [instance_id, user_id, activity_ids, classification_ids, taxonomy_ids, edit_action], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new activity taxonomy in pmt",
                        "message": err,
                        "value": activityId
                    });
                    updatePMTCalls("activity_taxonomy", "fail");
                    deferred.reject();
                }
                updatePMTCalls("activity_taxonomy", "pass");
                deferred.resolve(result.rows[0].response);
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "new activity taxonomy in pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// edit a location record in PMT
function editLocation(activityId, location, locationId, deleteRecord) {
    var deferred = q.defer();
    try {
        // database function parameters
        var instance_id = MIS_INTEGRATOR.instance_id;
        var user_id = MIS_INTEGRATOR.user_id;
        var activity_id = activityId;
        var location_id = locationId || null;
        var delete_record = deleteRecord || false;
        var boundary_id = null;
        var feature_id = null;
        var admin_level = null;
        var key_value_data = null;
        if (location) {
            boundary_id = location.boundary_id;
            feature_id = location.feature_id;
            admin_level = location.admin_level;
            key_value_data = {
                "_admin0": location.admin0,
                "_admin1": location.admin1,
                "_admin2": location.admin2
            };
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "new location in pmt",
                    "message": err,
                    "value": activityId
                });
                deferred.reject();
            }
            updatePMTCalls("location", "calls");
            client.query('SELECT * FROM pmt_edit_location($1,$2,$3,$4,$5,$6,$7,$8,$9)', [instance_id, user_id, activity_id, location_id, boundary_id, feature_id, admin_level, key_value_data, delete_record], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new location in pmt",
                        "message": err,
                        "value": activityId
                    });
                    updatePMTCalls("location", "fail");
                    deferred.reject();
                }
                if (result) {
                    if (result.rows[0].response.id && result.rows[0].response.message.search("Internal Error") < 0) {
                        updatePMTCalls("location", "pass");
                        deferred.resolve(result.rows[0].response);
                    }
                    else {
                        // add issue to report
                        MIS_INTEGRATOR.issues.push({
                            "error": "new location in pmt",
                            "message": "database error (likely from too many integration updates - run integration again",
                            "value": activityId
                        });
                        updatePMTCalls("location", "fail");
                        deferred.reject();
                    }
                }
                else {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "new location in pmt",
                        "message": "no response from the server",
                        "value": activityId
                    });
                    updatePMTCalls("location", "fail");
                    deferred.reject();
                }
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "new location in pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// replaces all funders for an activity in PMT
function replaceAllParticipants(activityId, orgIds, roleId) {
    var deferred = q.defer();
    try {
        // database function parameters
        var instance_id = MIS_INTEGRATOR.instance_id;
        var user_id = MIS_INTEGRATOR.user_id;
        var activity_id = activityId;
        var role_id = roleId;
        var organization_ids = orgIds.join(',');

        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "participation in pmt",
                    "message": err,
                    "value": activityId
                });
                deferred.reject();
            }
            updatePMTCalls("participant", "calls");
            client.query('SELECT * FROM pmt_replace_participation($1,$2,$3,$4,$5)', [instance_id, user_id, activity_id, role_id, organization_ids], function (err, result) {
                done();
                if (err || result === null) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "participation in pmt",
                        "message": err,
                        "value": activityId
                    });
                    updatePMTCalls("participant", "fail");
                    deferred.reject();
                }
                var idx = result.rows[0].response.message.search("Internal Error");
                var id = result.rows[0].response.id || result.rows[0].response.activity_id;
                if (id !== null && idx === -1) {
                    updatePMTCalls("participant", "pass");
                    deferred.resolve(result.rows[0].response);
                }
                else {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "participation in pmt",
                        "message": result.rows[0].response.message,
                        "value": activityId
                    });
                    updatePMTCalls("participant", "fail");
                    deferred.reject();
                }
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "participation in pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// create a relationship between activity and contact
function addContactToActivity(activityId, contactId) {
    var deferred = q.defer();
    try {
        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "actvity contact in pmt",
                    "message": err,
                    "value": activityId
                });
                deferred.reject();
            }
            client.query('INSERT INTO activity_contact (activity_id, contact_id) VALUES ($1,$2)', [activityId, contactId], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "actvity contact in pmt",
                        "message": err,
                        "value": activityId
                    });
                    deferred.reject();
                }
                deferred.resolve(result);
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "actvity contact in pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// create a relationship between activity and contact
function replaceContactToActivity(activityId, contactId) {
    var deferred = q.defer();
    try {
        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                // add issue to report
                MIS_INTEGRATOR.issues.push({
                    "error": "actvity contact in pmt",
                    "message": err,
                    "value": activityId
                });
                deferred.reject();
            }
            client.query('DELETE FROM activity_contact WHERE activity_id = $1', [activityId], function (err, result) {
                done();
                if (err) {
                    // add issue to report
                    MIS_INTEGRATOR.issues.push({
                        "error": "actvity contact in pmt",
                        "message": err,
                        "value": activityId
                    });
                    deferred.reject();
                }
                client.query('INSERT INTO activity_contact (activity_id, contact_id) VALUES ($1,$2)', [activityId, contactId], function (err, result) {
                    done();
                    if (err) {
                        // add issue to report
                        MIS_INTEGRATOR.issues.push({
                            "error": "actvity contact in pmt",
                            "message": err,
                            "value": activityId
                        });
                        deferred.reject();
                    }
                    deferred.resolve(result);
                });
                deferred.resolve(result);
            });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "actvity contact in pmt",
            "message": ex.message,
            "value": activityId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// set location taxonomies (new/existing)
function setLocationTaxonomies(locationId, boundary) {
    var deferred = q.defer();
    try {
        var classification_ids = [];
        // add Geographic Precision taxonomy based on admin level
        classification_ids.push(GEO_PRECISION[boundary.admin_level]);
        // add National/Local taxonomy based on admin level
        classification_ids.push(boundary.admin_level === 0 ? LOCAL_NATIONAL.national : LOCAL_NATIONAL.local);
        // add Taxonomies to be assigend to ALL locations
        classification_ids = _.union(classification_ids, ALL_LOCATION_CLASSES);

        // validate pg object in the config by the pmtId
        if (typeof config.pg[MIS_INTEGRATOR.pmt_id] !== 'object') {
            // error
            deferred.reject();
        }

        // create connection to database
        var conString = "postgres://" + config.pg[MIS_INTEGRATOR.pmt_id].user + ":" +
            config.pg[MIS_INTEGRATOR.pmt_id].password + "@" +
            config.pg[MIS_INTEGRATOR.pmt_id].host + "/" + config.pg[MIS_INTEGRATOR.pmt_id].database;


        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                deferred.reject();
            }
            updatePMTCalls("location_taxonomy", "calls");
            client.query('DELETE FROM location_taxonomy WHERE location_id = $1 AND ' +
                'classification_id NOT IN (SELECT id FROM classification WHERE taxonomy_id = 5)', [locationId], function (err, result) {
                    done();
                    if (err) {
                        // add issue to report
                        MIS_INTEGRATOR.issues.push({
                            "error": "location taxonomy in pmt",
                            "message": err,
                            "value": locationId
                        });
                        updatePMTCalls("location_taxonomy", "fail");
                        deferred.reject();
                    }
                    updatePMTCalls("location_taxonomy", "pass");
                    updatePMTCalls("location_taxonomy", "calls");
                    client.query('INSERT FROM location_taxonomy (location_id, classification_id) ' +
                        'SELECT $1, id FROM classification WHERE id = ANY($2)', [locationId, classification_ids], function (err, result) {
                            done();
                            if (err) {
                                // add issue to report
                                MIS_INTEGRATOR.issues.push({
                                    "error": "location taxonomy in pmt",
                                    "message": err,
                                    "value": locationId
                                });
                                updatePMTCalls("location_taxonomy", "fail");
                                deferred.reject();
                            }
                            updatePMTCalls("location_taxonomy", "pass");
                            deferred.resolve(result);
                        });
                });
        });
    }
    catch (ex) {
        // add issue to report
        MIS_INTEGRATOR.issues.push({
            "error": "location taxonomy in pmt",
            "message": ex.message,
            "value": locationId
        });
        deferred.reject();
    }
    return deferred.promise;
}

// -------------------------------------------------------
// MIS Integration Process: Utility Functions
// -------------------------------------------------------

// reset the integrator with a clean data model
function resetIntegrator() {
    // integration statistics
    var stats = {
        total: 0,       // MIS record count
        new: 0,         // MIS new records (not in PMT)
        matched: 0,     // MIS matched records (in PMT)
        changed: 0,     // MIS matched and changed records (in PMT)
        missing: 0,     // PMT records not in MIS
        created: 0,     // new MIS grants created in PMT
        updated: 0,     // matched MIS grants updated in PMT
        deleted: 0,     // missing MIS grants deleted in PMT
        untouched: 0    // matched MIS grants unchanged in PMT
    };
    // model for tracking calls to PMT
    var pmt = {
        total: 0,              // PMT record count (before integration)
        new_orgs: null,           // new PMT organizations found in MIS
        new_contacts: null,       // new PMT contacts found in MIS 
        delete_activities: [], // array of pmt activities to delete (not found in MIS)
        api: [
            {
                table: "activity",
                calls: 0,
                pass: 0,
                fail: 0
            },
            {
                table: "activity_taxonomy",
                calls: 0,
                pass: 0,
                fail: 0
            },
            {
                table: "contact",
                calls: 0,
                pass: 0,
                fail: 0
            },
            {
                table: "financial",
                calls: 0,
                pass: 0,
                fail: 0
            },
            {
                table: "location",
                calls: 0,
                pass: 0,
                fail: 0
            },
            {
                table: "location_taxonomy",
                calls: 0,
                pass: 0,
                fail: 0
            },
            {
                table: "organization",
                calls: 0,
                pass: 0,
                fail: 0
            },
            {
                table: "participant",
                calls: 0,
                pass: 0,
                fail: 0
            }
        ]
    };
    return {
        running: false,             // t/f the integrator is running
        step: 0,                    // step the integrator is currently on (0 - not running)
        steps: 10,                  // total number of steps in the process
        step_message: null,         // step message for UI
        error: null,                // error message, if error occurrs that terminates the integration 
        issues: [],                 // error messages collected during the process, but were not fatal (integration continues)
        stats: stats,               // MIS integration statistics object
        pmt: pmt,                    // PMT integration tracking object
        instance_id: null,          // PMT instance id (Passed by API call that initiaties integration)
        user_id: null,              // PMT user id (Passed by API call that initiaties integration)
        data_group_id: 769,         // PMT data group for AGRA (id does not change from database to database)
        pmt_id: null                // PMT database id (Passed by API call that initiaties integration)
    };

}

// update the pmt api tracking model with values
function updatePMTCalls(table, key, ct) {
    _.each(MIS_INTEGRATOR.pmt.api, function (ele) {
        if (ele.table === table) {
            if (ct !== undefined) {
                ele[key] = ele[key] + ct;
            }
            else {
                ele[key]++;
            }
        }
    });
}

// returns the last string value in a name
function lastName(name) {
    try {
        var n = name.trim().split(" ");
        return n[n.length - 1];
    }
    catch (ex) {
        console.log(ex);
        return name;
    }
}

// returns all but the last string in a name
function firstName(name) {
    try {
        var n = name.trim().split(" ");
        n.pop();
        return n.join(" ").trim();
    }
    catch (ex) {
        console.log(ex);
        return name;
    }
}