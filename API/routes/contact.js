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

// request all active contacts
router.post('/pmt_contacts', jsonParser, function (req, res) {
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
            client.query('SELECT * FROM pmt_contacts()', function (err, result) {
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

// edit an contact
router.post('/pmt_edit_contact', jsonParser, function (req, res) {
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

        // validate contact_id (optional paramater: required only for update & delete)
        var contact_id = req.body.contact_id;
        if (typeof contact_id !== 'number') {
            contact_id = null;
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
            client.query('SELECT * FROM pmt_edit_contact($1,$2,$3,$4,$5,$6,$7)', [instance_id, user_id, activity_id, data_group_id, contact_id, key_value_data, delete_record], function (err, result) {
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