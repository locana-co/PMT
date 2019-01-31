var express = require('express');
var bodyParser = require('body-parser');
var router = express.Router();
var multer = require('multer');
var csv = require('csv-parse');
var fs = require('file-system');

var upload = multer({ dest: 'uploads/' });
// get the applications configuration
var config = require("../config.js");
// connect to the database
var pg = require('pg');

// create application/json parser
var jsonParser = bodyParser.json();

// create application/x-www-form-urlencoded parser
var urlencodedParser = bodyParser.urlencoded({ extended: false })

// request a global search on the activity table for a key term
router.post('/pmt_global_search', jsonParser, function (req, res) {
    try {
        // validate search text
        var search_text = req.body.search_text;
        if (typeof search_text !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a valid search text (string) in the JSON object of your HTTP POST." });
            return;
        }

        // validate data group ids (optional paramater) to restrict data search to
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
            client.query('SELECT * FROM pmt_global_search($1, $2)', [search_text, data_group_ids], function (err, result) {
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

// request auto complete or type ahead feature data from columns of the
// activity table, each text element returned is restricted to 100 characters
router.post('/pmt_auto_complete', jsonParser, function (req, res) {
    try {
        // validate search text

        var filter_fields = req.body.filter_fields;
        if (typeof filter_fields !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a valid list of filter fields (string) in the JSON object of your HTTP POST." });
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
            client.query('SELECT * FROM pmt_auto_complete($1)', [filter_fields], function (err, result) {
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

// request export csv
router.post('/pmt_export', jsonParser, function (req, res) {
    try {

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({
                errCode: 400,
                status: "ERROR",
                message: "You must specify a pmtId as an integer in the JSON of your HTTP POST."
            });
            return;
        }

        // validate export function, pmt_export by default (required)
        var export_function = req.body.export || 'pmt_export';
        if (typeof export_function !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a valid list of filter fields (string) in the JSON object of your HTTP POST." });
            return;
        }

        // validate data group ids (required)
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a data_group_ids as an string in the JSON of your HTTP POST." });
            return
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

        // validate pg object in the config by the pmtId
        if (typeof config.pg[pmtId] !== 'object') {
            res.status(400).json({
                errCode: 400,
                status: "ERROR",
                message: "Your pmtId does not correspond to a valid database instance."
            });
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
            client.query('SELECT * FROM ' + export_function + '($1,$2,$3,$4,$5,$6,$7,$8)',
                [data_group_ids, classification_ids, org_ids, imp_org_ids, fund_org_ids, start_date, end_date, unassigned_taxonomy_ids], function (err, result) {
                    done();
                    if (err) {
                        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                        return;
                    }

                    var json = [];

                    // replace null values with empty string
                    result.rows.forEach(function (val) {
                        Object.keys(val.response).forEach(function (key) {
                            if (val.response[key] == null) {
                                val.response[key] = ""
                            }
                        })
                    });

                    // remove extra response object
                    result.rows.forEach(function (val, i) {
                        json.push(val.response);
                    });

                    json = JSON.stringify(json);

                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                    res.end(json);
                });
        });
    }
    catch (ex) {
        res.status(500).json({
            errCode: 500,
            status: "ERROR",
            message: "There was an error in the execution of API request. Contact the administrator."
        });
        return;
    }
});

// request all intersected boundaries for a given wkt point
router.post('/pmt_boundaries_by_point', jsonParser, function (req, res) {
    try {

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({
                errCode: 400,
                status: "ERROR",
                message: "You must specify a pmtId as an integer in the JSON of your HTTP POST."
            });
            return;
        }

        // validate wktpoint (required)
        var wktPoint = req.body.wktPoint;
        if (typeof wktPoint !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a wktPoint as an string in the JSON of your HTTP POST." });
            return
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[pmtId] !== 'object') {
            res.status(400).json({
                errCode: 400,
                status: "ERROR",
                message: "Your pmtId does not correspond to a valid database instance."
            });
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
            client.query('SELECT * FROM pmt_boundaries_by_point($1)', [wktPoint], function (err, result) {
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
        res.status(500).json({
            errCode: 500,
            status: "ERROR",
            message: "There was an error in the execution of API request. Contact the administrator."
        });
        return;
    }
});

// request filtered boundary features
router.post('/pmt_boundary_filter', jsonParser, function (req, res) {
    try {

        // validate boundary_table (required)
        var boundary_table = req.body.boundary_table;
        if (typeof boundary_table !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a boundary table as an string in the JSON of your HTTP POST." });
            return
        }

        // validate query_field (required)
        var query_field = req.body.query_field;
        if (typeof query_field !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a query field as an string in the JSON of your HTTP POST." });
            return
        }

        // validate query (required)
        var query = req.body.query;
        if (typeof query !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a query as an string in the JSON of your HTTP POST." });
            return
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({
                errCode: 400,
                status: "ERROR",
                message: "You must specify a pmtId as an integer in the JSON of your HTTP POST."
            });
            return;
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[pmtId] !== 'object') {
            res.status(400).json({
                errCode: 400,
                status: "ERROR",
                message: "Your pmtId does not correspond to a valid database instance."
            });
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
            client.query('SELECT * FROM pmt_boundary_filter($1,$2,$3)', [boundary_table, query_field, query], function (err, result) {
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
        res.status(500).json({
            errCode: 500,
            status: "ERROR",
            message: "There was an error in the execution of API request. Contact the administrator."
        });
        return;
    }
});

// request extent for boundary feature(s)
router.post('/pmt_boundary_extents', jsonParser, function (req, res) {
    try {

        // validate boundary_table (required)
        var boundary_table = req.body.boundary_table;
        if (typeof boundary_table !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a boundary table as an string in the JSON of your HTTP POST." });
            return
        }

        // validate feature_names (required)
        var feature_names = req.body.feature_names;
        if (typeof feature_names !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a feature name(s) as an string in the JSON of your HTTP POST." });
            return
        }

        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({
                errCode: 400,
                status: "ERROR",
                message: "You must specify a pmtId as an integer in the JSON of your HTTP POST."
            });
            return;
        }

        // validate pg object in the config by the pmtId
        if (typeof config.pg[pmtId] !== 'object') {
            res.status(400).json({
                errCode: 400,
                status: "ERROR",
                message: "Your pmtId does not correspond to a valid database instance."
            });
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
            client.query('SELECT * FROM pmt_boundary_extents($1,$2)', [boundary_table, feature_names], function (err, result) {
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
        res.status(500).json({
            errCode: 500,
            status: "ERROR",
            message: "There was an error in the execution of API request. Contact the administrator."
        });
        return;
    }
});

// request boundary hierarchy (menu structure)
router.post('/pmt_boundary_hierarchy', jsonParser, function (req, res) {
    try {

        // validate boundary_type (required) the type of boundary hierarchy to create
        var boundary_type = req.body.boundary_type;
        if (typeof boundary_type !== 'string' && typeof boundary_type !== 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide boundary type as a string in the JSON object of your HTTP POST." });
            return;
        }

        // validate admin_levels (optional paramater) admin levels to construct hierarchy for given boundary type
        var admin_levels = req.body.admin_levels;
        if (typeof admin_levels !== 'string' || typeof admin_levels == 'undefined') {
            admin_levels = null;
        }

        // validate filter_features (optional paramater) names of features in the highest admin level to restrict data to
        var filter_features = req.body.filter_features;
        if (typeof filter_features !== 'string' || typeof filter_features == 'undefined') {
            filter_features = null;
        }

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
            client.query('SELECT * FROM pmt_boundary_hierarchy($1,$2,$3,$4)', [boundary_type, admin_levels, filter_features, data_group_ids], function (err, result) {
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

// request a refresh of the materialized views
router.post('/pmt_refresh_views', jsonParser, function (req, res) {
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
            client.query('SELECT * FROM pmt_refresh_views($1,$2)', [user_id, instance_id], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }
                var json = JSON.stringify(result.rows);

                client.query('VACUUM ANALYZE;', function (err, result) {
                    console.log('....... VACUUM ANALYZE completed');
                });
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

// text search pmt boundaries via name field
router.post('/pmt_boundary_search', jsonParser, function(req, res) {
    try {
        // validate pmtId
        var pmtId = req.body.pmtId;
        if (typeof pmtId !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtId as an integer in the JSON of your HTTP POST." });
            return;
        }

        // validate boundary_type (required) the type of boundary hierarchy to create
        var boundary_type = req.body.boundary_type;
        if (typeof boundary_type !== 'string' && typeof boundary_type !== 'undefined') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide boundary type as a string in the JSON object of your HTTP POST." });
            return;
        }

        // validate search text
        var search_text = req.body.search_text;
        if (typeof search_text !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a valid search text (string) in the JSON object of your HTTP POST." });
            return;
        }

        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;

        // connect to db
        pg.connect(conString, function (err, client, done) {
            if (err) {
                return console.error('error fetching client from pool', err);
            }
            // make call to pmt_boundary_search
            client.query('SELECT * FROM  pmt_boundary_search($1,$2)', [boundary_type, search_text], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
                    return;
                }
                var json = JSON.stringify(result.rows);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                res.end(json);
            }); // query
        }); // connect
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator." });
        return;
    }
});

// request to convert a csv to json
router.post('/csv_to_json', upload.any(), function (req, res, next) {
    var path = "";
    try {
        var files = req.files;
        if (files && files.length === 1) {
            //get our file. 
            var file = files[0];
            var arr = [];
            path = file.path;
            fs.createReadStream(path).pipe(csv().on('data', function (data) {
                arr.push(data);
            }).on("end", function () {
                //review data and remove any common typos
                var segment = "", final = [];

                if (arr.length > 0) {
                    var colCount = arr[0].toString().split(',').length; // get column count to know how to rebuild array
                    var stringArray = arr.toString(); //turn array into 1 big string
                    var values = stringArray.split(','); //turn big string into individual pieces
                    for (var x = 0; x < values.length; x++) {
                        values[x] = values[x].replace("    "," ").replace("   "," ").replace("  "," ").trim(); //perform data clean up
                        if(segment != ""){segment +=",";} //add commas back in
                        segment += values[x];
                        if((x+1)%colCount === 0){
                            //every time we hit the number for a new line, store our segment and reset
                            final.push(segment.split(',')); //store each row as an array of strings
                            segment = "";
                        }
                    }
                }

                //convert array of csv into json
                var json = JSON.stringify(final);
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                res.end(json);

                fs.unlinkSync(path); //remove created file
            }).on("error", function (e) {
                //convert array of csv into json
                fs.unlinkSync(path); //remove created file
                res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error reading the file. Please review all error messages.", error: e.toString() });
                return;
            }));
        }
        return;
    }
    catch (ex) {
        console.log('error fetching client from pool');
        fs.unlinkSync(path); //remove created file
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});


module.exports = router;