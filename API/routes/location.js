var express = require('express');
var bodyParser = require('body-parser');
var router = express.Router();

// get the applications configuration
var config = require("../config.js");
// connect to the database
var pg = require('pg');

// create application/json parser
var jsonParser = bodyParser.json()

// create application/x-www-form-urlencoded parser
var urlencodedParser = bodyParser.urlencoded({ extended: false })

// request locations by aggregated to boundary centroid features
router.post('/pmt_locations_for_boundaries', jsonParser, function (req, res) {
    try {

        // validate boundary_id (required) boundary to aggregate too
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a boundary id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
        }

        // validate org_ids (optional paramater) organizations to restrict data to
        var org_ids = req.body.org_ids;
        if (typeof org_ids !== 'string' || typeof org_ids == 'undefined') {
            org_ids = null;
        }

        // validate fund_org_ids (optional paramater) funding organizations to restrict data to
        var fund_org_ids = req.body.fund_org_ids;
        if (typeof fund_org_ids !== 'string' || typeof fund_org_ids == 'undefined') {
            fund_org_ids = null;
        }

        // validate imp_org_ids (optional paramater) implementing organizations to restrict data to
        var imp_org_ids = req.body.imp_org_ids;
        if (typeof imp_org_ids !== 'string' || typeof imp_org_ids == 'undefined') {
            imp_org_ids = null;
        }

        // validate classification_ids (optional paramater) classifications to restrict data to
        var classification_ids = req.body.classification_ids;
        if (typeof classification_ids !== 'string' || typeof classification_ids == 'undefined') {
            classification_ids = null;
        }

        // validate start_date (optional paramater) to restrict data to
        var start_date = req.body.start_date;
        if (typeof start_date !== 'string' || typeof start_date == 'undefined') {
            start_date = null;
        }

        // validate end_date (optional paramater) to restrict data to
        var end_date = req.body.end_date;
        if (typeof end_date !== 'string' || typeof end_date == 'undefined') {
            end_date = null;
        }

        // validate unassigned_taxonomy_ids (optional paramater) to restrict data that is not assigned a taxonomy
        var unassigned_taxonomy_ids = req.body.unassigned_taxonomy_ids;
        if (typeof unassigned_taxonomy_ids !== 'string' || typeof unassigned_taxonomy_ids == 'undefined') {
            unassigned_taxonomy_ids = null;
        }

        // validate activity_ids (optional paramater) list of activity ids to restrict data to
        var activity_ids = req.body.activity_ids;
        if (typeof activity_ids !== 'string' || typeof activity_ids == 'undefined') {
            activity_ids = null;
        }

        // validate boundary_filter (optional paramater) to restrict data that is in one or more of the specified boundary features
        var boundary_filter = req.body.boundary_filter;
        if (typeof boundary_filter !== 'object' || typeof boundary_filter == 'undefined' || boundary_filter == null) {
            boundary_filter = null;
        }
        else {
            boundary_filter = JSON.stringify(boundary_filter)
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[pmtId] !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Your pmtId does not correspond to a valid database instance." });
            return;
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_locations_for_boundaries($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)',
                [boundary_id, data_group_ids, classification_ids, org_ids, imp_org_ids, fund_org_ids, start_date, end_date, unassigned_taxonomy_ids, activity_ids, boundary_filter], function (err, result) {
                    done();
                    if (err) {
                        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                        return;
                    }
                    var json = JSON.stringify(result.rows);
                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                    res.end(json);
                });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});

// requests activity ids for a feature in a boundary
router.post('/pmt_activity_ids_by_boundary', jsonParser, function (req, res) {
    try {
        // validate boundary_id (required) boundary to aggregate too
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a boundary id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate feature_id (required) boundary feature to aggregate too
        var feature_id = req.body.feature_id;
        if (typeof feature_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a boundary id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
        }

        // validate org_ids (optional paramater) organizations to restrict data to
        var org_ids = req.body.org_ids;
        if (typeof org_ids !== 'string' || typeof org_ids == 'undefined') {
            org_ids = null;
        }

        // validate fund_org_ids (optional paramater) funding organizations to restrict data to
        var fund_org_ids = req.body.fund_org_ids;
        if (typeof fund_org_ids !== 'string' || typeof fund_org_ids == 'undefined') {
            fund_org_ids = null;
        }

        // validate imp_org_ids (optional paramater) implementing organizations to restrict data to
        var imp_org_ids = req.body.imp_org_ids;
        if (typeof imp_org_ids !== 'string' || typeof imp_org_ids == 'undefined') {
            imp_org_ids = null;
        }

        // validate classification_ids (optional paramater) classifications to restrict data to
        var classification_ids = req.body.classification_ids;
        if (typeof classification_ids !== 'string' || typeof classification_ids == 'undefined') {
            classification_ids = null;
        }

        // validate start_date (optional paramater) to restrict data to
        var start_date = req.body.start_date;
        if (typeof start_date !== 'string' || typeof start_date == 'undefined') {
            start_date = null;
        }

        // validate end_date (optional paramater) to restrict data to
        var end_date = req.body.end_date;
        if (typeof end_date !== 'string' || typeof end_date == 'undefined') {
            end_date = null;
        }

        // validate unassigned_taxonomy_ids (optional paramater) to restrict data that is not assigned a taxonomy
        var unassigned_taxonomy_ids = req.body.unassigned_taxonomy_ids;
        if (typeof unassigned_taxonomy_ids !== 'string' || typeof unassigned_taxonomy_ids == 'undefined') {
            unassigned_taxonomy_ids = null;
        }

        // validate activity_ids (optional paramater) list of activity ids to restrict data to
        var activity_ids = req.body.activity_ids;
        if (typeof activity_ids !== 'string' || typeof activity_ids == 'undefined') {
            activity_ids = null;
        }

        // validate boundary_filter (optional paramater) to restrict data that is in one or more of the specified boundary features
        var boundary_filter = req.body.boundary_filter;
        if (typeof boundary_filter !== 'object' || typeof boundary_filter == 'undefined' || boundary_filter == null) {
            boundary_filter = null;
        }
        else {
            boundary_filter = JSON.stringify(boundary_filter)
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[pmtId] !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Your pmtId does not correspond to a valid database instance." });
            return;
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_activity_ids_by_boundary($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)',
                [boundary_id, feature_id, data_group_ids, classification_ids, org_ids, imp_org_ids, fund_org_ids, start_date, end_date, unassigned_taxonomy_ids, activity_ids, boundary_filter], function (err, result) {
                    done();
                    if (err) {
                        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                        return;
                    }
                    var json = JSON.stringify(result.rows);
                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                    res.end(json);
                });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request locations by aggregated to boundary centroid features
router.post('/pmt_locations', jsonParser, function (req, res) {
    try {

        // validate location_ids (required) to collect
        var location_ids = req.body.location_ids;
        if (typeof location_ids !== 'string' && typeof location_ids !== 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide location_ids as comma delimited  string of location ids in the JSON object of your HTTP POST." });
            return;
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[pmtId] !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Your pmtId does not correspond to a valid database instance." });
            return;
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_locations($1)', [location_ids], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }
                var json = JSON.stringify(result.rows);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                res.end(json);
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request activities within wkt polygon
router.post('/pmt_activities_by_polygon', jsonParser, function (req, res) {
    try {

        // validate wkt (required)
        var wkt = req.body.wkt;
        if (typeof wkt !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide wkt a string in the JSON object of your HTTP POST." });
            return;
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
        }

        // validate org_ids (optional paramater) organizations to restrict data to
        var org_ids = req.body.org_ids;
        if (typeof org_ids !== 'string' || typeof org_ids == 'undefined') {
            org_ids = null;
        }

        // validate fund_org_ids (optional paramater) funding organizations to restrict data to
        var fund_org_ids = req.body.fund_org_ids;
        if (typeof fund_org_ids !== 'string' || typeof fund_org_ids == 'undefined') {
            fund_org_ids = null;
        }

        // validate imp_org_ids (optional paramater) implementing organizations to restrict data to
        var imp_org_ids = req.body.imp_org_ids;
        if (typeof imp_org_ids !== 'string' || typeof imp_org_ids == 'undefined') {
            imp_org_ids = null;
        }

        // validate classification_ids (optional paramater) classifications to restrict data to
        var classification_ids = req.body.classification_ids;
        if (typeof classification_ids !== 'string' || typeof classification_ids == 'undefined') {
            classification_ids = null;
        }

        // validate start_date (optional paramater) to restrict data to
        var start_date = req.body.start_date;
        if (typeof start_date !== 'string' || typeof start_date == 'undefined') {
            start_date = null;
        }

        // validate end_date (optional paramater) to restrict data to
        var end_date = req.body.end_date;
        if (typeof end_date !== 'string' || typeof end_date == 'undefined') {
            end_date = null;
        }

        // validate unassigned_taxonomy_ids (optional paramater) to restrict data that is not assigned a taxonomy
        var unassigned_taxonomy_ids = req.body.unassigned_taxonomy_ids;
        if (typeof unassigned_taxonomy_ids !== 'string' || typeof unassigned_taxonomy_ids == 'undefined') {
            unassigned_taxonomy_ids = null;
        }

        // validate activity_ids (optional paramater) list of activity ids to restrict data to
        var activity_ids = req.body.activity_ids;
        if (typeof activity_ids !== 'string' || typeof activity_ids == 'undefined') {
            activity_ids = null;
        }

        // validate boundary_filter (optional paramater) to restrict data that is in one or more of the specified boundary features
        var boundary_filter = req.body.boundary_filter;
        if (typeof boundary_filter !== 'object' || typeof boundary_filter == 'undefined' || boundary_filter == null) {
            boundary_filter = null;
        }
        else {
            boundary_filter = JSON.stringify(boundary_filter)
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_activities_by_polygon($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)', [wkt, data_group_ids, classification_ids, org_ids, imp_org_ids, fund_org_ids, start_date, end_date, unassigned_taxonomy_ids, activity_ids, boundary_filter], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }
                var json = JSON.stringify(result.rows);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                res.end(json);
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request activity count by taxonomy
router.post('/pmt_activity_count_by_taxonomy', jsonParser, function (req, res) {
    try {

        // validate taxonomy_id (required) taxonomy to aggregate to
        var taxonomy_id = req.body.taxonomy_id;
        if (typeof taxonomy_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a taxonomy id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate activity ids (required) activities to restrict data to
        var activity_ids = req.body.activity_ids;
        if (typeof activity_ids !== 'string' || typeof activity_ids == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a string of comma delimited activity ids in the JSON object of your HTTP POST." });
            return;
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_activity_count_by_taxonomy($1, $2)', [taxonomy_id, activity_ids], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }
                var json = JSON.stringify(result.rows);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                res.end(json);
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request activity count by participating org
router.post('/pmt_activity_count_by_participants', jsonParser, function (req, res) {
    try {

        // validate classification_id (required) organization role classification to aggregate to
        var classification_id = req.body.classification_id;
        if (typeof classification_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a classification id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate activity ids (required) activities to restrict data to
        var activity_ids = req.body.activity_ids;
        if (typeof activity_ids !== 'string' || typeof activity_ids == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a string of comma delimited activity ids in the JSON object of your HTTP POST." });
            return;
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_activity_count_by_participants($1, $2)', [classification_id, activity_ids], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }
                var json = JSON.stringify(result.rows);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                res.end(json);
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request feature information for a boundary feature
router.post('/pmt_boundary_feature', jsonParser, function (req, res) {
    try {

        // validate boundary_id (required) the requested boundary
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a boundary id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate feature_id (required) the requested feature of boundary
        var feature_id = req.body.feature_id;
        if (typeof feature_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a feature id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_boundary_feature($1, $2)', [boundary_id, feature_id], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }
                var json = JSON.stringify(result.rows);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                res.end(json);
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// matches submitted location object to requested boundary type
router.post('/pmt_boundary_match', jsonParser, function (req, res) {
    try {
        
        // validate boundary_type (require paramater) boundary type to search (gadm, eth, ssd)
        var boundary_type = req.body.boundary_type;
        if (typeof boundary_type !== 'string' || typeof boundary_type == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a boundary_type as a string in the JSON object of your HTTP POST." });
            return;
        }

        // validate locations (optional paramater) location object to search boundary for
        // { "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": null,"_admin2": null,"_admin_level": 0,"_iati_identifier": "2007 PASS 001"}
        var locations = req.body.locations;
        if (typeof locations !== 'object' || typeof locations == 'undefined' || locations == null) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a locations as a json object in the JSON object of your HTTP POST." });
            return;
        }
        else {
            locations = JSON.stringify(locations)
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[pmtId] !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Your pmtId does not correspond to a valid database instance." });
            return;
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_boundary_match($1, $2)', [boundary_type, locations], function (err, result) {
                    done();
                    if (err) {
                        console.log(err);
                        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                        return;
                    }
                    var json = JSON.stringify(result.rows);
                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                    res.end(json);
                });
        });
    }
    catch (ex) {
        console.log(ex);
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

module.exports = router;