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

// request participating regions for the 2x2 analysis
router.post('/pmt_2x2_regions', jsonParser, function (req, res) {
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
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;
        
        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            client.query('SELECT * FROM pmt_2x2_regions()', function (err, result) {
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

// request 2x2 analysis for a country & region
router.post('/pmt_2x2', jsonParser, function (req, res) {
    try {
        // validate country (required)
        var country = req.body.country;
        if (typeof country !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a country parameter as a string in the JSON of your HTTP POST." });
            return;
        }
        
        // validate region (required)
        var region = req.body.region;
        if (typeof region !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a region parameter as a string in the JSON of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_2x2($1,$2)', [country, region], function (err, result) {
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

// request statistics for activities by taxonomy
router.post('/pmt_stat_activity_by_tax', jsonParser, function (req, res) {
    try {
        // validate taxonomy_id (required) taxonomy to aggregate to
        var taxonomy_id = req.body.taxonomy_id;
        if (typeof taxonomy_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a taxonomy id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        
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
        
        // validate boundary_id (optional paramater) boundary related to feature_id to restrict data to
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            boundary_id = null;
        }
        
        // validate feature_id (optional paramater) feature of boundary to restrict data to
        var feature_id = req.body.feature_id;
        if (typeof feature_id !== 'number') {
            feature_id = null;
        }
           
        // validate record_limit (optional paramater) number of records to restrict data to
        var record_limit = req.body.record_limit;
        if (typeof record_limit !== 'number') {
            record_limit = null;
        }
           
        // validate filter_classification_ids (optional paramater) filter for provided taxonomy_id to filter response to
        var filter_classification_ids = req.body.filter_classification_ids;
        if (typeof filter_classification_ids !== 'string' || typeof filter_classification_ids == 'undefined') {
            filter_classification_ids = null;
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
            client.query('SELECT * FROM pmt_stat_activity_by_tax($1,$2,$3,$4,$5,$6,$7,$8,$9)', [taxonomy_id, data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id, record_limit, filter_classification_ids], function (err, result) {
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

// request statistics for investments by funder
router.post('/pmt_stat_invest_by_funder', jsonParser, function (req, res) {
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
        
        // validate boundary_id (optional paramater) boundary related to feature_id to restrict data to
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            boundary_id = null;
        }
        
        // validate feature_id (optional paramater) feature of boundary to restrict data to
        var feature_id = req.body.feature_id;
        if (typeof feature_id !== 'number') {
            feature_id = null;
        }
        
        // validate limit_records (optional paramater) limit number of returned records
        var limit_records = req.body.limit_records;
        if (typeof limit_records !== 'number') {
            limit_records = null;
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
            client.query('SELECT * FROM pmt_stat_invest_by_funder($1,$2,$3,$4,$5,$6,$7)', [data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id, limit_records], function (err, result) {
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

// request activities by investments
router.post('/pmt_activity_by_invest', jsonParser, function (req, res) {
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
        
        // validate boundary_id (optional paramater) boundary related to feature_id to restrict data to
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            boundary_id = null;
        }
        
        // validate feature_id (optional paramater) feature of boundary to restrict data to
        var feature_id = req.body.feature_id;
        if (typeof feature_id !== 'number') {
            feature_id = null;
        }
        
        // validate limit_records (optional paramater) limit number of returned records
        var limit_records = req.body.limit_records;
        if (typeof limit_records !== 'number') {
            limit_records = null;
        }
        
        // validate field_list (optional paramater) a list of additional fields to include in return
        var field_list = req.body.field_list;
        if (typeof field_list !== 'string' || typeof field_list == 'undefined') {
            field_list = null;
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
            client.query('SELECT * FROM pmt_activity_by_invest($1,$2,$3,$4,$5,$6,$7,$8)', [data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id, limit_records, field_list], function (err, result) {
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

// request statistics for activity counts by organization and role
router.post('/pmt_stat_by_org', jsonParser, function (req, res) {
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
        
        // validate org_role_id (required paramater) boundary related to feature_id to restrict data to
        var org_role_id = req.body.org_role_id;
        if (typeof org_role_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "The org_role_id is a required parameter." });
            return;
        }
        
        // validate boundary_id (optional paramater) boundary related to feature_id to restrict data to
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            boundary_id = null;
        }
        
        // validate feature_id (optional paramater) feature of boundary to restrict data to
        var feature_id = req.body.feature_id;
        if (typeof feature_id !== 'number') {
            feature_id = null;
        }
        
        // validate limit_records (optional paramater) limit number of returned records
        var limit_records = req.body.limit_records;
        if (typeof limit_records !== 'number') {
            limit_records = null;
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
            client.query('SELECT * FROM pmt_stat_by_org($1,$2,$3,$4,$5,$6,$7,$8)', [data_group_ids, classification_ids, start_date, end_date, org_role_id, boundary_id, feature_id, limit_records], function (err, result) {
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

// request partner pivot table
router.post('/pmt_partner_pivot', jsonParser, function (req, res) {
    try {
        // validate row_taxonomy_id (required) taxonomy for row/y-axis of pivot
        var row_taxonomy_id = req.body.row_taxonomy_id;
        if (typeof row_taxonomy_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a row taxonomy id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        
        // validate column_taxonomy_id (required) taxonomy for column/x-axis of pivot
        var column_taxonomy_id = req.body.column_taxonomy_id;
        if (typeof column_taxonomy_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a column taxonomy id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        
        // validate org_role_id (required) the organization role id for organizations to include in data
        var org_role_id = req.body.org_role_id;
        if (typeof org_role_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a organization role id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        
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
        
        // validate boundary_id (optional paramater) boundary related to feature_id to restrict data to
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            boundary_id = null;
        }
        
        // validate feature_id (optional paramater) feature of boundary to restrict data to
        var feature_id = req.body.feature_id;
        if (typeof feature_id !== 'number') {
            feature_id = null;
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
            client.query('SELECT * FROM pmt_partner_pivot($1,$2,$3,$4,$5,$6,$7,$8,$9)', [row_taxonomy_id, column_taxonomy_id, org_role_id, data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id], function (err, result) {
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

// request boundary pivot table
router.post('/pmt_boundary_pivot', jsonParser, function (req, res) {
    try {
        // validate pivot_boundary_id  (required) boundary for row/y-axis or column/x-axis of pivot
        var pivot_boundary_id  = req.body.pivot_boundary_id ;
        if (typeof pivot_boundary_id  !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a pivot boundary id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        
        // validate pivot_taxonomy_id (required) taxonomy for row/y-axis or column/x-axis of pivot
        var pivot_taxonomy_id = req.body.pivot_taxonomy_id;
        if (typeof pivot_taxonomy_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a pivot taxonomy id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        
        // validate boundary_as_row  (optional parameter) t/f to make the boundary the row
        var boundary_as_row  = req.body.boundary_as_row ;
        if (typeof boundary_as_row  !== 'boolean') {
            boundary_as_row = false;
        }
        
        // validate org_role_id (required) the organization role id for organizations to include in data
        var org_role_id = req.body.org_role_id;
        if (typeof org_role_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a organization role id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        
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
        
        // validate boundary_id (required) boundary related to feature_id to restrict data to
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a boundary id as an integer in the JSON object of your HTTP POST." });
            return;
        }
        
        // validate feature_id (required) feature of boundary to restrict data to
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
            client.query('SELECT * FROM pmt_boundary_pivot($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)', [pivot_boundary_id , pivot_taxonomy_id, boundary_as_row, org_role_id, data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id], function (err, result) {
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

// request overview statisics
router.post('/pmt_overview_stats', jsonParser, function (req, res) {
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
        
        // validate boundary_id (optional paramater) boundary related to feature_id to restrict data to
        var boundary_id = req.body.boundary_id;
        if (typeof boundary_id !== 'number') {
            boundary_id = null;
        }
        
        // validate feature_ids (optional paramater) feature of boundary to restrict data to
        var feature_ids = req.body.feature_ids;
        if (typeof feature_ids !== 'string' || typeof feature_ids == 'undefined') {
            feature_ids = null;
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
            client.query('SELECT * FROM pmt_overview_stats($1,$2,$3,$4,$5,$6)', [data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_ids], function (err, result) {
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