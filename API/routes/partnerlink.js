var express = require('express');
var bodyParser = require('body-parser');
var router = express.Router();

// get the applications configuration
var config = require("../config.js");
// connect to the database
var pg = require('pg');

// create application/json parser
var jsonParser = bodyParser.json();

// request all partner link data in d3 sankey data format
router.post('/pmt_partner_sankey', jsonParser, function (req, res) {
    try {

        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
        }
        
        // validate classification_ids (optional paramater) classifications to restrict data to
        var classification_ids = req.body.classification_ids;
        if (typeof classification_ids !== 'string' || typeof classification_ids == 'undefined') {
            classification_ids = null;
        }
        
        // validate org_ids (optional paramater) organizations to restrict data to
        var org_ids = req.body.org_ids;
        if (typeof org_ids !== 'string' || typeof org_ids == 'undefined') {
            org_ids = null;
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
                res.status(500).json({errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err});
                done();
                return;
            }

            client.query("SELECT * FROM pmt_partner_sankey($1, $2, $3, $4, $5, $6)",
                    [data_group_ids, classification_ids, org_ids, start_date, end_date, unassigned_taxonomy_ids], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err});
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
        res.status(400).json({errCode: 400, status: "ERROR", message: "/pmt_partner_sankey failed", ex: ex});
    }
});

// request activities by organization name and parnerlink node level
router.post('/pmt_partner_sankey_activities', jsonParser, function (req, res) {
    try {
                
        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify data_group_ids as an string in the JSON of your HTTP POST." });
            return;
        }
              
        // check organization
        var organization = req.body.organization;
        if (typeof organization !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify an organization as a string in the JSON of your HTTP POST." });
            return;
        }        
        
        // check partnerlink_level
        var partnerlink_level = req.body.partnerlink_level;
        if (typeof partnerlink_level !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a partnerlink_level as number in the JSON of your HTTP POST." });
            return;
        }
        
        // check pmtId
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
            client.query('SELECT * FROM pmt_partner_sankey_activities($1, $2, $3)',[data_group_ids, organization, partnerlink_level], function (err, result) {
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
        console.log(ex);
        res.status(400).json({ errCode: 400, status: "ERROR", message: "/pmt_partner_sankey_activities failed", ex: ex });
    }
});

module.exports = router;