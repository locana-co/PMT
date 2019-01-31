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

// request activity record
router.post('/pmt_activity', jsonParser, function (req, res) {
    try {
        // validate activity_id
        var activity_id = req.body.id;
        if (typeof activity_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an id as an integer in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_activity($1)', [activity_id], function (err, result) {
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

// request an activity detail record for the purpose of editing
router.post('/pmt_activity_detail', jsonParser, function (req, res) {
    try {

        // validate activity id
        var activity_id = req.body.id;
        if (typeof activity_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an id as an integer in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_activity_detail($1)', [activity_id], function (err, result) {
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

// request an activity detail record for the purpose of editing
router.post('/pmt_activity_details', jsonParser, function (req, res) {
    try {

        // validate activity_ids (array of ids)
        var activity_ids = req.body.activity_ids;
        // validate data_group_id (single integer)
        var data_group_id = req.body.data_group_id;

        if ((typeof data_group_id !== 'number') || (activity_ids.constructor !== Array || typeof activity_ids == 'undefined')) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an activity_ids as an integer array OR a data_group_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // check active_only record boolean (default true)
        var active_only = req.body.active_only;
        if (typeof active_only !== 'boolean') {
            active_only = true;
        }

        // validate limit_record (optional)
        var limit_record = req.body.limit_record;
        if (typeof limit_record !== 'number') {
            limit_record = null;
        }

        // validate offset_record (optional)
        var offset_record = req.body.offset_record;
        if (typeof offset_record !== 'number') {
            offset_record = null;
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
            client.query('SELECT * FROM pmt_activity_details($1,$2,$3,$4,$5)', [activity_ids, data_group_id, active_only, limit_record, offset_record], function (err, result) {
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

// request list of activities
router.post('/pmt_activities', jsonParser, function (req, res) {
    try {
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
            boundary_filter = JSON.stringify(boundary_filter);
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
            client.query('SELECT * FROM pmt_activities($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)',
                [data_group_ids, classification_ids, org_ids, imp_org_ids, fund_org_ids, start_date, end_date, unassigned_taxonomy_ids, activity_ids, boundary_filter], function (err, result) {
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

// request list of activities (all: active & inactive) non-filterable
router.post('/pmt_activities_all', jsonParser, function (req, res) {
    try {
        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
        }

        // check only_active record boolean (default true)
        var only_active = req.body.only_active;
        if (typeof only_active !== 'boolean') {
            only_active = true;
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
            client.query('SELECT * FROM pmt_activities_all($1, $2)', [data_group_ids, only_active], function (err, result) {
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

// request total count of activities for a given filter
router.post('/pmt_activity_count', jsonParser, function (req, res) {
    try {

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
            client.query('SELECT * FROM pmt_activity_count($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)',
                [data_group_ids, classification_ids, org_ids, imp_org_ids, fund_org_ids, start_date, end_date, unassigned_taxonomy_ids, activity_ids, boundary_filter], function (err, result) {
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

// request list of titles for activities by given ids
router.post('/pmt_activity_titles', jsonParser, function (req, res) {
    try {

        // validate activity_ids
        var activity_ids = req.body.activity_ids;
        if (activity_ids.constructor !== Array || typeof activity_ids == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify an activity_ids as an integer array in the JSON of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_activity_titles($1)', [activity_ids], function (err, result) {
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

// request list of family tree titles for activities
router.post('/pmt_activity_family_titles', jsonParser, function (req, res) {
    try {

        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
        }

        // validate classification_ids (optional paramater) data groups to restrict data to
        var classification_ids = req.body.classification_ids;
        if (typeof classification_ids !== 'string' || typeof classification_ids == 'undefined') {
            classification_ids = null;
        }
        console.log("req", req);
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
            client.query('SELECT * FROM pmt_activity_family_titles($1,$2)', [data_group_ids, classification_ids], function (err, result) {
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

// request a valid parent activity id (filter by data group)
router.post('/pmt_get_valid_id', jsonParser, function (req, res) {
    try {

        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
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
            client.query('SELECT * FROM pmt_get_valid_id($1)', [data_group_ids], function (err, result) {
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

// edit the active status (t/f) for an activity record (and all related records)
router.post('/pmt_activate_activity', jsonParser, function (req, res) {
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

        // validate activity_id
        var activity_id = req.body.activity_id;
        if (typeof activity_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an activity_id as an integer in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_activate_activity($1,$2,$3)', [instance_id, user_id, activity_id], function (err, result) {
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

// edit an activity
router.post('/pmt_edit_activity', jsonParser, function (req, res) {
    try {
        //if editType is passed and is a star, then skip call to db
        if (req.body.editType && req.body.editType === "*") {
            var json = JSON.stringify([{ "response": { id: req.body.activity_id, message: 'Success' } }]);
            res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
            res.end(json);
        } else {
            //perform normal call
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

            // validate activity_id (optional paramater: required only for update & delete)
            var activity_id = req.body.activity_id;
            if (typeof activity_id !== 'number') {
                activity_id = null;
            }

            // validate data_group_id (optional paramater: required only for create)
            var data_group_id = req.body.data_group_id;
            if (typeof data_group_id !== 'number') {
                data_group_id = null;
            }

            // validate key_value_data (optional paramater: required only for update & create) containing activity field data
            var key_value_data = req.body.key_value_data;
            if (typeof key_value_data !== 'object' || typeof key_value_data == 'undefined' || key_value_data == null) {
                key_value_data = null;
            }
            else {
                key_value_data = JSON.stringify(key_value_data);
            }

            // check delete record boolean
            var delete_record = req.body.delete_record;
            if (typeof delete_record !== 'boolean') {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a delete_record property in the JSON object of your HTTP POST." });
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
                client.query('SELECT * FROM pmt_edit_activity($1,$2,$3,$4,$5,$6)', [instance_id, user_id, activity_id, data_group_id, key_value_data, delete_record], function (err, result) {
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



    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// edit an activity's taxonomies
router.post('/pmt_edit_activity_taxonomy', jsonParser, function (req, res) {
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

        // validate activity_ids
        var activity_ids = req.body.activity_ids;
        if (typeof activity_ids !== 'string' || typeof activity_ids == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an activity_ids as a string in the JSON object of your HTTP POST." });
            return;
        }

        // validate edit action (pmt enum: add, delete, replace)
        var edit_action = req.body.edit_action;
        if (typeof edit_action !== 'string' || typeof edit_action == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a edit_action as a string in the JSON object of your HTTP POST." });
            return;
        }
        else {
            if (edit_action !== 'add' && edit_action !== 'delete' && edit_action !== 'replace') {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide edit_action as: add, delete, replace, in the JSON object of your HTTP POST." });
                return;
            }
        }

        // validate classification_ids (optional paramater: required for replace and add)
        var classification_ids = req.body.classification_ids;
        if (typeof classification_ids !== 'string' || typeof classification_ids == 'undefined') {
            classification_ids = null;
        }

        // validate taxonomy_ids (optional paramater: required for delete)
        var taxonomy_ids = req.body.taxonomy_ids;
        if (typeof taxonomy_ids !== 'string' || typeof taxonomy_ids == 'undefined') {
            taxonomy_ids = null;
        }

        // must include classification_ids or taxonomy_ids for delete actions
        if (edit_action === 'delete' & classification_ids === null & taxonomy_ids === null) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide either classification_ids or taxonomy_ids as a string in the JSON object of your HTTP POST." });
            return;
        }

        // must include classification_ids if action is not delete
        if ((edit_action === 'add' || edit_action === 'replace') && classification_ids === null) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide classification_ids as a string in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_edit_activity_taxonomy($1,$2,$3,$4,$5,$6)', [instance_id, user_id, activity_ids, classification_ids, taxonomy_ids, edit_action], function (err, result) {
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

// edit an activity's financial record
router.post('/pmt_edit_financial', jsonParser, function (req, res) {
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

        // validate activity_id
        var activity_id = req.body.activity_id;
        if (typeof activity_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an activity_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate financial_id (optional paramater: required only for update & delete)
        var financial_id = req.body.financial_id;
        if (typeof financial_id !== 'number') {
            financial_id = null;
        }

        // validate key_value_data (optional paramater: required only for update & create) containing activity field data
        var key_value_data = req.body.key_value_data;
        if (typeof key_value_data !== 'object' || typeof key_value_data == 'undefined' || key_value_data == null) {
            key_value_data = null;
        }
        else {
            key_value_data = JSON.stringify(key_value_data);
        }

        // check delete record boolean
        var delete_record = req.body.delete_record;
        if (typeof delete_record !== 'boolean') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a delete_record property in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_edit_financial($1,$2,$3,$4,$5,$6)', [instance_id, user_id, activity_id, financial_id, key_value_data, delete_record], function (err, result) {
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

// edit an activity's financial taxonomies
router.post('/pmt_edit_financial_taxonomy', jsonParser, function (req, res) {
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

        // validate financial_ids
        var financial_ids = req.body.financial_ids;
        if (typeof financial_ids !== 'string' || typeof financial_ids == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an financial_ids as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate edit action (pmt enum: add, delete, replace)
        var edit_action = req.body.edit_action;
        if (typeof edit_action !== 'string' || typeof edit_action == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a edit_action as a string in the JSON object of your HTTP POST." });
            return;
        }
        else {
            if (edit_action !== 'add' && edit_action !== 'delete' && edit_action !== 'replace') {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide edit_action as: add, delete, replace, in the JSON object of your HTTP POST." });
                return;
            }
        }

        // validate classification_ids (optional paramater: required for replace and add)
        var classification_ids = req.body.classification_ids;
        if (typeof classification_ids !== 'string' || typeof classification_ids == 'undefined') {
            classification_ids = null;
        }

        // validate taxonomy_ids (optional paramater: required for delete)
        var taxonomy_ids = req.body.taxonomy_ids;
        if (typeof taxonomy_ids !== 'string' || typeof taxonomy_ids == 'undefined') {
            taxonomy_ids = null;
        }

        // must include classification_ids or taxonomy_ids for delete actions
        if (edit_action === 'delete' & classification_ids === null & taxonomy_ids === null) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide either classification_ids or taxonomy_ids as a string in the JSON object of your HTTP POST." });
            return;
        }

        // must include classification_ids if action is not delete
        if ((edit_action === 'add' || edit_action === 'replace') && classification_ids === null) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide classification_ids as a string in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_edit_financial_taxonomy($1,$2,$3,$4,$5,$6)', [instance_id, user_id, financial_ids, classification_ids, taxonomy_ids, edit_action], function (err, result) {
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

// edit an activity's participation
router.post('/pmt_edit_participation', jsonParser, function (req, res) {
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

        // validate activity_id
        var activity_id = req.body.activity_id;
        if (typeof activity_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an activity_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate organization_id
        var organization_id = req.body.organization_id;
        if (typeof organization_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an organization_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate participation_id (optional paramater: required for delete)
        var participation_id = req.body.participation_id;
        if (typeof participation_id !== 'number') {
            participation_id = null;
        }

        // validate classification_ids
        var classification_ids = req.body.role_ids;
        if (typeof classification_ids !== 'string' || typeof classification_ids == 'undefined') {
            classification_ids = null;
        }

        // validate edit action (pmt enum: add, delete, replace)
        var edit_action = req.body.edit_action;
        if (typeof edit_action !== 'string' || typeof edit_action == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a edit_action as a string in the JSON object of your HTTP POST." });
            return;
        }
        else {
            if (edit_action !== 'add' && edit_action !== 'delete' && edit_action !== 'replace') {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide edit_action as: add, delete, replace, in the JSON object of your HTTP POST." });
                return;
            }
        }

        // must include classification_ids if action is not delete
        if ((edit_action === 'add' || edit_action === 'replace') && classification_ids === null) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide classification_ids as a string in the JSON object of your HTTP POST." });
            return;
        }

        // must include participation_id if action is add
        if (edit_action !== 'add' && participation_id === null) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide participation_id as a string in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_edit_participation($1,$2,$3,$4,$5,$6,$7)', [instance_id, user_id, activity_id, organization_id, participation_id, classification_ids, edit_action], function (err, result) {
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
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// replace an activity's participation by role
router.post('/pmt_replace_participation', jsonParser, function (req, res) {
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

        // validate activity_id
        var activity_id = req.body.activity_id;
        if (typeof activity_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an activity_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate role_id
        var role_id = req.body.role_id;
        if (typeof role_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an role_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate organization_ids
        var organization_ids = req.body.organization_ids;
        if (typeof organization_ids !== 'string' || typeof organization_ids == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an organization_ids as a string listing of organization ids in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_replace_participation($1,$2,$3,$4,$5)', [instance_id, user_id, activity_id, role_id, organization_ids], function (err, result) {
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

// edit an activity's location record
router.post('/pmt_edit_location', jsonParser, function (req, res) {
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

        // validate activity_id
        var activity_id = req.body.activity_id;
        if (typeof activity_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an activity_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // check delete record boolean
        var delete_record = req.body.delete_record;
        if (typeof delete_record !== 'boolean') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a delete_record as a boolean in the JSON object of your HTTP POST." });
            return;
        }

        // validate location_id (optional paramater: required only for delete)
        var location_id = req.body.location_id;
        if (typeof location_id !== 'number') {
            if (delete_record) {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a location_id as a integer in the JSON object of your HTTP POST." });
                return;
            }
            else {
                location_id = null;
            }
        }

        // validate boundary_id (optional paramater: required only for create)
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            if (delete_record) {
                boundary_id = null;
            }
            else {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a boundary_id as a integer in the JSON object of your HTTP POST." });
                return;
            }
        }

        // validate feature_id (optional paramater: required only for create)
        var feature_id = req.body.feature_id;
        if (typeof feature_id !== 'number') {
            if (delete_record) {
                feature_id = null;
            }
            else {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a feature_id as a integer in the JSON object of your HTTP POST." });
                return;
            }
        }

        // validate admin_level (optional paramater: required only for create)
        var admin_level = req.body.admin_level;
        if (typeof admin_level !== 'number') {
            if (delete_record) {
                admin_level = null;
            }
            else {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a admin_level as a integer in the JSON object of your HTTP POST." });
                return;
            }
        }

        // validate key_value_data (optional paramater: required only for create) containing location field data
        var key_value_data = req.body.key_value_data;
        if (typeof key_value_data !== 'object' || typeof key_value_data == 'undefined' || key_value_data == null) {
            if (delete_record) {
                key_value_data = null;
            }
            else {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a key_value_data as a json object in the JSON object of your HTTP POST." });
                return;
            }
        }
        else {
            key_value_data = JSON.stringify(key_value_data);
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
            client.query('SELECT * FROM pmt_edit_location($1,$2,$3,$4,$5,$6,$7,$8,$9)', [instance_id, user_id, activity_id, location_id, boundary_id, feature_id, admin_level, key_value_data, delete_record], function (err, result) {
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

// request one valid id to use as a model for creating new activites
router.post('/pmt_get_valid_id', jsonParser, function (req, res) {
    try {
        // validate data_group_id 
        var data_group_id = req.body.data_group_id;
        if (typeof data_group_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a data_group_id as an integer in the JSON of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_get_valid_id($1)', [data_group_id], function (err, result) {
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

module.exports = router;