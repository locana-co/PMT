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

// edit a detail
router.post('/pmt_edit_detail', jsonParser, function (req, res) {
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

        // validate detail_id (optional paramater: required only for update & delete)
        var detail_id = req.body.detail_id;
        if (typeof detail_id !== 'number') {
            detail_id = null;
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
            client.query('SELECT * FROM pmt_edit_detail($1,$2,$3,$4,$5,$6)', [instance_id, user_id, activity_id, detail_id, key_value_data, delete_record], function (err, result) {
                done();

                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }

                var json = JSON.stringify(result.rows);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                console.log(json);
                res.end(json);
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// edit a detail taxonomy
router.post('/pmt_edit_detail_taxonomy', jsonParser, function (req, res) {
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

        // validate detail_ids
        var detail_ids = req.body.detail_ids;
        if (typeof detail_ids !== 'string' || typeof detail_ids == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an detail_ids as a string in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_edit_detail_taxonomy($1,$2,$3,$4,$5,$6)', [instance_id, user_id, detail_ids, classification_ids, taxonomy_ids, edit_action], function (err, result) {
                done();

                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }

                var json = JSON.stringify(result.rows);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                console.log(json);
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