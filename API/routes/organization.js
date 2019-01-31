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

// request organizations participating in activities
router.post('/pmt_org_inuse', jsonParser, function (req, res) {
    try {
        // validate data_group_ids (optional paramater)
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
        }
        
        // validate org_role_ids (optional paramater)
        var org_role_ids = req.body.org_role_ids;
        if (typeof org_role_ids !== 'string' || typeof org_role_ids == 'undefined') {
            org_role_ids = null;
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
            client.query('SELECT * FROM pmt_org_inuse($1,$2)', [data_group_ids, org_role_ids], function (err, result) {
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
        console.log(ex); res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request all active organizations
router.post('/pmt_orgs', jsonParser, function (req, res) {
    try {
        
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
        var conString = "postgres://" + config.pg[pmtId].user + ":" + config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;
        
        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_orgs()', function (err, result) {
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
        console.log(ex); res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request all active user organizations
router.post('/pmt_user_orgs', jsonParser, function (req, res) {
    try {
        
        // validate pmtInstance
        var pmtInstance = req.body.pmtInstance;
        if (typeof pmtInstance !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtInstance as an integer in the JSON of your HTTP POST." });
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
        var conString = "postgres://" + config.pg[pmtId].user + ":" + config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;
        
        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_user_orgs($1)', [pmtInstance], function (err, result) {
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
        console.log(ex); res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// crud operations for editing organizations
router.post('/pmt_edit_organization', jsonParser, function(req,res){
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

        // validate organization_id (optional paramater: required only for update & delete)
        var organization_id = req.body.organization_id;
        if (typeof organization_id !== 'number') {
            organization_id = null;
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
            client.query('SELECT * FROM pmt_edit_organization($1,$2,$3,$4,$5)', [instance_id, user_id, organization_id, key_value_data, delete_record], function (err, result) {
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

// compare organization names to prevent duplicates
router.post('/pmt_check_orgs', jsonParser, function (req, res) {
    try {
        // validate pmtInstance
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // validate search text
        var searchText = req.body.search_text;
        if (typeof  searchText !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a search_text parameter as an string in the JSON of your HTTP POST." });
            return;
        }
        
        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" + config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;
        
        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            
            client.query('SELECT * FROM pmt_check_orgs($1)', [searchText], function (err, result) {
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
        console.log(ex); res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// consolidate duplicated organizations
router.post('/pmt_consolidate_orgs', jsonParser, function(req,res){
    try {
        // validate instance_id
        var instance_id = req.body.instance_id;
        if (typeof instance_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an instance_id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        // validate user_id (required)
        var user_id = req.body.user_id;
        if (typeof user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an user_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate organization id to KEEP (required)
        var organization_to_keep_id = req.body.organization_to_keep_id;
        if (typeof organization_to_keep_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an organization_to_keep_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate organizations to consolidate (required)
        var organization_ids_to_consolidate = req.body.organization_ids_to_consolidate;
        if (organization_ids_to_consolidate.constructor !== Array || typeof organization_ids_to_consolidate == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify an organization_ids_to_consolidate as an integer array in the JSON of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_consolidate_orgs($1,$2,$3,$4)', [instance_id, user_id, organization_to_keep_id, organization_ids_to_consolidate], function (err, result) {
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