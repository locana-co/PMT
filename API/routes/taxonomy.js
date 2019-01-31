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

// request all active classifications for a taxonomy id
router.post('/pmt_classifications', jsonParser, function (req, res) {
    try {
        // validate taxonomy_id
        var taxonomy_id = req.body.taxonomy_id;
        if (typeof taxonomy_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a taxonomy_id as an integer in the JSON object of your HTTP POST." });
            return;
        }

        // validate data_group_ids (optional paramater) data groups to restrict data to
        var data_group_ids = req.body.data_group_ids;
        if (typeof data_group_ids !== 'string' || typeof data_group_ids == 'undefined') {
            data_group_ids = null;
        }

        // validate instance_id (optional paramater) data groups to restrict data to
        var instance_id = req.body.instance_id;
        if (typeof instance_id !== 'number') {
            instance_id = null;
        }

        // validate locations_only (optional paramater) response restricted to activities with locations only
        var locations_only = req.body.locations_only;
        if (typeof locations_only !== 'booelan' || typeof locations_only == 'undefined') {
            locations_only = false;
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
            client.query('SELECT * FROM pmt_classifications($1,$2,$3,$4)', [taxonomy_id, data_group_ids, instance_id, locations_only], function (err, result) {
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

// request all active taxonomies
router.post('/pmt_taxonomies', jsonParser, function (req, res) {
    try {
         // validate instance_id
         var instance_id = req.body.instance_id;
         if (typeof instance_id !== 'number') {
             res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an instance_id as an integer in the JSON object of your HTTP POST." });
             return;
         }

        // validate return_core
        var return_core = req.body.return_core;
        if (typeof return_core !== 'boolean') {
            return_core = false;
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
            client.query('SELECT * FROM pmt_taxonomies($1,$2)', [instance_id, return_core], function (err, result) {
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

// edit a taxonomy
router.post('/pmt_edit_taxonomy', jsonParser, function (req, res) {
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

        // validate taxonomy_id (optional paramater: required only for update & delete)
        var taxonomy_id = req.body.taxonomy_id;
        if (typeof taxonomy_id !== 'number') {
            taxonomy_id = null;
        }

        // validate key_value_data (optional paramater: required only for update & create) containing field data
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
            delete_record = false;
        }

        // must provide key value data if not deleting
        if(!delete_record && key_value_data == null){
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide key_value_data as a string in the JSON object of your HTTP POST when executing an update/create operation." });
            return;
        }

        // must provide taxonomy id when deleting
        if(delete_record && taxonomy_id == null){
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide taxonomy_id as a integer in the JSON object of your HTTP POST when executing a delete operation." });
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
            client.query('SELECT * FROM pmt_edit_taxonomy($1,$2,$3,$4,$5)', [instance_id, user_id, taxonomy_id, key_value_data, delete_record], function (err, result) {
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

// edit a taxonomy classification
router.post('/pmt_edit_classification', jsonParser, function (req, res) {
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

        // validate classification_id (optional paramater: required only for update & delete)
        var classification_id = req.body.classification_id;
        if (typeof classification_id !== 'number') {
            classification_id = null;
        }

        // validate taxonomy_id (optional paramater: required only for create)
        var taxonomy_id = req.body.taxonomy_id;
        if (typeof taxonomy_id !== 'number') {
            taxonomy_id = null;
        }

        // validate key_value_data (optional paramater: required only for update & create) containing field data
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
            delete_record = false;
        }

        // must provide key value data if not deleting
        if(!delete_record && key_value_data == null){
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide key_value_data as a string in the JSON object of your HTTP POST when executing an update/create operation." });
            return;
        }

        // must provide classification id when deleting
        if(delete_record && classification_id == null){
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide classification_id as a integer in the JSON object of your HTTP POST when executing a delete operation." });
            return;
        }

        // must provide taxonomy id when creating new record
        if(!delete_record && classification_id == null && taxonomy_id == null){
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide taxonomy_id as a integer in the JSON object of your HTTP POST when executing a create operation." });
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
            client.query('SELECT * FROM pmt_edit_classification($1,$2,$3,$4,$5,$6)', [instance_id, user_id, classification_id, taxonomy_id, key_value_data, delete_record], function (err, result) {
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

// filterable listing of taxonomies
router.post('/pmt_taxonomy_search', jsonParser, function (req, res) {
    try {
         // validate instance_id (optional)
         var instance_id = req.body.instance_id;
         if (typeof instance_id !== 'number') {
            instance_id = null;
         }

        // validate search_text (optional)
        var search_text = req.body.search_text;
        if (typeof search_text !== 'string') {
            search_text = null;
        }
        
         // validate offsetter (optional)
         var offsetter = req.body.offsetter;
         if (typeof offsetter !== 'number') {
            offsetter = null;
         }

         // validate limiter (optional)
         var limiter = req.body.limiter;
         if (typeof limiter !== 'number') {
            limiter = null;
         }

         // validate return_core (optional)
         var return_core = req.body.return_core;
         if (typeof return_core !== 'boolean') {
            return_core = false;
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
            client.query('SELECT * FROM pmt_taxonomy_search($1,$2,$3,$4,$5)', [instance_id, search_text, offsetter, limiter, return_core], function (err, result) {
                done();
                console.log(err);
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

// filterable count of taxonomies
router.post('/pmt_taxonomy_count', jsonParser, function (req, res) {
    try {
         // validate instance_id (optional)
         var instance_id = req.body.instance_id;
         if (typeof instance_id !== 'number') {
            instance_id = null;
         }

        // validate search_text (optional)
        var search_text = req.body.search_text;
        if (typeof search_text !== 'string') {
            search_text = null;
        }

        // validate exclude_ids (optional)
        var exclude_ids = req.body.exclude_ids;
        if (typeof exclude_ids !== 'string') {
            exclude_ids = null;
        }

         // validate return_core (optional)
         var return_core = req.body.return_core;
         if (typeof return_core !== 'boolean') {
            return_core = false;
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
            client.query('SELECT * FROM pmt_taxonomy_count($1,$2,$3,$4)', [instance_id, search_text, exclude_ids, return_core], function (err, result) {
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

// filterable listing of classifications for a given taxonomy
router.post('/pmt_classification_search', jsonParser, function (req, res) {
    try {
         // validate taxonomy_id (required)
         var taxonomy_id = req.body.taxonomy_id;
         if (typeof taxonomy_id !== 'number') {
             res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an taxonomy_id as an integer in the JSON object of your HTTP POST." });
             return;
         }

        // validate search_text (optional)
        var search_text = req.body.search_text;
        if (typeof search_text !== 'string') {
            search_text = null;
        }

         // validate offsetter (optional)
         var offsetter = req.body.offsetter;
         if (typeof offsetter !== 'number') {
            offsetter = null;
         }

         // validate limiter (optional)
         var limiter = req.body.limiter;
         if (typeof limiter !== 'number') {
            limiter = null;
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
            client.query('SELECT * FROM pmt_classification_search($1,$2,$3,$4)', [taxonomy_id, search_text, offsetter, limiter], function (err, result) {
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

// filterable count of classifications for a given taxonomy
router.post('/pmt_classification_count', jsonParser, function (req, res) {
    try {
         // validate taxonomy_id (required)
         var taxonomy_id = req.body.taxonomy_id;
         if (typeof taxonomy_id !== 'number') {
             res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an taxonomy_id as an integer in the JSON object of your HTTP POST." });
             return;
         }

        // validate search_text (optional)
        var search_text = req.body.search_text;
        if (typeof search_text !== 'string') {
            search_text = null;
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
            client.query('SELECT * FROM pmt_classification_count($1,$2)', [taxonomy_id, search_text], function (err, result) {
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