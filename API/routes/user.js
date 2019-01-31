var express = require('express');
var bodyParser = require('body-parser');
var router = express.Router();
var Util = require('../util.js');
var Q = require('q');
var _ = require('underscore');

// get the applications configuration
var config = require("../config.js");
// connect to the database
var pg = require('pg');

// JSON Web Token Library - https://github.com/auth0/node-jsonwebtoken
var jwt = require('jsonwebtoken');

// E-mail sending module - http://nodemailer.com/
var nodemailer = require('nodemailer');

// request user authentication
router.post('/pmt_user_auth', function (req, res) {
    try {
        // check username
        var username = req.body.username;
        if (typeof username !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a username as a string in the JSON object of your HTTP POST." });
            return;
        }

        // check password
        var password = req.body.password;
        if (typeof password !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a password as a string in the JSON object of your HTTP POST." });
            return;
        }

        // check pmtInstance
        var pmtInstance = req.body.pmtInstance;
        if (typeof pmtInstance !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtInstance as an integer in the JSON of your HTTP POST." });
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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_user_auth($1,$2,$3)', [username, password, pmtInstance], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                    return;
                }
                if (result.rows.length < 1) {
                    res.status(401).json({ errCode: 401, status: "ERROR", message: "invalid credentials" });
                }
                // information about the user that is returned from the pmt_user_auth SQL Function
                var userObj = result.rows[0].response;
                // add ata token to userOBJ
                userObj["ata-token"] = config["ata-accessToken"];
                // fail if we don't get a good response.
                if (typeof userObj.id === 'undefined') {
                    if (typeof userObj.message != 'undefined') {
                        res.status(401).json({ errCode: 401, status: "ERROR", message: userObj.message });
                    }
                    else {
                        res.status(401).json({ errCode: 401, status: "ERROR", message: "Invalid user name or password." });
                    }
                }
                // good credentials, go forward with creating JWT.
                else {
                    // add the PMT ID from the body of the post
                    userObj.pmtId = req.body.pmtId;
                    respondWithJWT(res, userObj);
                }
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});

// request all users
router.post('/pmt_users', function (req, res) {
    try {
        // check pmtInstance
        var pmtInstance = req.body.pmtInstance;
        if (typeof pmtInstance !== 'number') {
            pmtInstance = null;
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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            // pmt_users is an overloaded method, call the appropriate method based on instance id
            if (pmtInstance) {
                client.query('SELECT * FROM pmt_users($1)', [pmtInstance], function (err, result) {
                    done();
                    if (err) {
                        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                        return;
                    }
                    var users = _.pluck(result.rows, 'response');
                    var json = JSON.stringify(users);
                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                    res.end(json);
                });
            }
            else {
                client.query('SELECT * FROM pmt_users()', function (err, result) {
                    done();
                    if (err) {
                        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                        return;
                    }
                    var users = _.pluck(result.rows, 'response');
                    var json = JSON.stringify(users);
                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                    res.end(json);
                });
            }

        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});

// find users
router.post('/pmt_find_users', function (req, res) {
    try {

        // check first_name
        var first_name = req.body.first_name;
        if (typeof first_name !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a first_name paramater as a string in the JSON object of your HTTP POST." });
            return;
        }

        // check last_name
        var last_name = req.body.last_name;
        if (typeof last_name !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a last_name paramater as a string in the JSON object of your HTTP POST." });
            return;
        }

        // check email
        var email = req.body.email;
        if (typeof email !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a email paramater as a string in the JSON object of your HTTP POST." });
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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_find_users($1,$2,$3)', [first_name, last_name, email], function (err, result) {
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

// request all roles
router.post('/pmt_roles', function (req, res) {
    try {

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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_roles()', function (err, result) {
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

// update user
router.patch('/pmt_user', function (req, res) {
    try {

        // check pmtInstance
        var pmtInstance = req.body.pmtInstance;
        if (typeof pmtInstance !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtInstance as an integer in the JSON of your HTTP POST." });
            return;
        }

        // check requested user id
        var request_user_id = req.body.request_user_id;
        if (typeof request_user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a request_user_id as a number in the JSON object of your HTTP POST." });
            return;
        }

        // check delete record boolean
        var delete_record = req.body.delete_record;
        if (typeof delete_record !== 'boolean') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a delete_record property in the JSON object of your HTTP POST." });
            return;
        }

        // check target_user has id, it is required for the delete and update operations
        var target_user_id = req.body.target_user.id;
        if (typeof target_user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an id parameter as an integer in the target_user object in the JSON object of your HTTP POST." });
            return;
        }

        // check target user properties
        var target_user = req.body.target_user;
        if (typeof target_user !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a target_user as a object in the JSON object of your HTTP POST." });
            return;
        }

        // check role id
        var role_id = req.body.target_user.role_id;
        if (typeof role_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a role_id as an integer in the target_user object in the JSON of your HTTP POST." });
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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_edit_user($1,$2,$3,$4,$5,$6)', [pmtInstance, request_user_id, target_user.id, JSON.stringify(target_user), role_id, delete_record], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                    return;
                }
                if (result.rows.length < 1) {
                    res.status(401).json({ errCode: 401, status: "ERROR", message: "Invalid request" });
                }
                // get the returned user information from the pmt_user funciton
                var userObj = result.rows[0].response;
                // fail if we don't get a good response.
                if (typeof userObj.id === 'undefined') {
                    res.status(401).json({ errCode: 401, status: "ERROR", message: "Invalid request" });
                }
                // completed update, proceed with success message
                else {
                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(JSON.stringify(userObj)) });
                    res.end(JSON.stringify(userObj));
                }
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});

// create user
router.post('/pmt_user', function (req, res) {
    try {

        // check pmtInstance
        var pmtInstance = req.body.pmtInstance;
        if (typeof pmtInstance !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtInstance as an integer in the JSON of your HTTP POST." });
            return;
        }

        // check requested user id
        var request_user_id = req.body.request_user_id;
        if (typeof request_user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a request_user_id as a number in the JSON object of your HTTP POST." });
            return;
        }

        // check target user properties
        var target_user = req.body.target_user;
        if (typeof target_user !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a target_user as a object in the JSON object of your HTTP POST." });
            return;
        }

        // check required fields for creating user
        if (!target_user._username || !target_user._email || !target_user._password || !target_user.organization_id ||
            !target_user.role_id || !target_user._first_name || !target_user._last_name) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a _first_name, _last_name, _username, _email, _password, role_id & organization_id as properties in the target_user JSON object of your HTTP POST." });
            return;
        }

        // check role id
        var role_id = req.body.target_user.role_id;
        if (typeof role_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a role_id as an integer in the target_user object in the JSON of your HTTP POST." });
            return;
        }

        // check url
        var url = req.body.url;
        if (typeof url !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a url as a string in the in the JSON of your HTTP POST." });
            return;
        }

        // check email property
        var email = req.body.email;
        if (typeof email !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an email as a object in the JSON object of your HTTP POST." });
            return;
        }

        // check required fields for email
        if (!email.subject || !email.body) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a subject and body as properties in the email JSON object of your HTTP POST." });
            return;
        }

        // check email subject is a string
        if (typeof email.subject !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an email subject as a string in the JSON object of your HTTP POST." });
            return;
        }

        // check email body is a string
        if (typeof email.body !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an email body as a string in the JSON object of your HTTP POST." });
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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_edit_user($1,$2,$3,$4,$5,$6)', [pmtInstance, request_user_id, null, JSON.stringify(target_user), role_id, false], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                    return;
                }
                if (result.rows.length < 1) {
                    res.status(401).json({ errCode: 401, status: "ERROR", message: "Invalid request" });
                }
                // get the returned user information from the pmt_user funciton
                var userObj = result.rows[0].response;
                // fail if we don't get a good response.
                if (typeof userObj.id === 'undefined') {
                    res.status(401).json({ errCode: 401, status: "ERROR", message: "User creation was unsuccessful. Contact the administrator." });
                }
                else {
                    // completed new account creation, send email with account credentials
                    var msg = {
                        email: target_user._email, // New User Address
                        subject: email.subject,
                        message: email.body + "\n \n" +
                        "url: " + url + "\n" +
                        "username: " + target_user._username + "\n" + // plaintext body
                        "password: " + target_user._password
                    };
                    // send new account creds to email
                    sendEmail(config.pg[pmtId].smpt, msg).then(function (response) {
                        res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(JSON.stringify(userObj)) });
                        res.end(JSON.stringify(userObj));
                    }).catch(function (err) {
                        // throw error
                        res.status(401).json({ errCode: 401, status: "ERROR", message: err });
                    })
                }
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});

// reset user password
router.post('/pmt_reset_password', function (req, res) {
    try {

        // check pmtInstance
        var pmtInstance = req.body.pmtInstance;
        if (typeof pmtInstance !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtInstance as an integer in the JSON of your HTTP POST." });
            return;
        }

        // check requested user id
        var request_user_id = req.body.request_user_id;
        if (typeof request_user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a request_user_id as a number in the JSON object of your HTTP POST." });
            return;
        }

        // check target_user has id, it is required for the delete and update operations
        var target_user_id = req.body.target_user.id;
        if (typeof target_user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an id parameter as an integer in the target_user object in the JSON object of your HTTP POST." });
            return;
        }

        // check target user properties
        var target_user = req.body.target_user;
        if (typeof target_user !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a target_user as a object in the JSON object of your HTTP POST." });
            return;
        }

        // check target user has _password
        var password = req.body.target_user._password;
        if (typeof password !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a _password paramater as a string in the target_user object in the JSON object of your HTTP POST." });
            return;
        }

        // check target user has _email
        var emailAddress = req.body.target_user._email;
        if (typeof emailAddress !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a _email paramater as a string in the target_user object in the JSON object of your HTTP POST." });
            return;
        }

        // check target user has _username
        var username = req.body.target_user._username;
        if (typeof username !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a _username paramater as a string in the target_user object in the JSON object of your HTTP POST." });
            return;
        }

        // check role id
        var role_id = req.body.target_user.role_id;
        if (typeof role_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a role_id as an integer in the target_user object in the JSON of your HTTP POST." });
            return;
        }

        // check url
        var url = req.body.url;
        if (typeof url !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a url as a string in the in the JSON of your HTTP POST." });
            return;
        }

        // check email object
        var email = req.body.email;
        if (typeof email !== 'object') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an email as a object in the JSON object of your HTTP POST." });
            return;
        }

        // check required fields for email object
        if (!email.subject || !email.body) {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a subject and body as properties in the email JSON object of your HTTP POST." });
            return;
        }

        // check email subject is a string
        if (typeof email.subject !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an email subject as a string in the JSON object of your HTTP POST." });
            return;
        }

        // check email body is a string
        if (typeof email.body !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide an email body as a string in the JSON object of your HTTP POST." });
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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_edit_user($1,$2,$3,$4,$5,$6)', [pmtInstance, request_user_id, target_user.id, JSON.stringify({ "_password": password }), role_id, false], function (err, result) {
                done();
                if (err) {
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                    return;
                }
                // send email with new credentials
                var json = JSON.stringify(result.rows);
                // send new credentials to user
                var msg = {
                    email: emailAddress,
                    subject: email.subject,
                    message: email.body + "\n \n" +
                    "url: " + url + "\n" +
                    "username: " + username + "\n" +
                    "password: " + password
                };
                // send new account credentials to email
                sendEmail(config.pg[pmtId].smpt, msg).then(function (response) {
                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(json) });
                    res.end(json);
                }).catch(function (err) {
                    // throw error
                    res.status(401).json({ errCode: 401, status: "ERROR", message: err });
                });
            });
        });
    }
    catch (ex) {
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});

// update user activity authorizations
router.post('/pmt_user_activities', function (req, res) {
    try {

        // check pmtInstance
        var pmtInstance = req.body.pmtInstance;
        if (typeof pmtInstance !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a pmtInstance as an integer in the JSON of your HTTP POST." });
            return;
        }

        // check requested user id
        var request_user_id = req.body.request_user_id;
        if (typeof request_user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a request_user_id as a number in the JSON object of your HTTP POST." });
            return;
        }

        // check target user id
        var target_user_id = req.body.target_user_id;
        if (typeof target_user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a target_user_id as a number in the JSON object of your HTTP POST." });
            return;
        }

        // check activity ids
        var activity_ids = req.body.activity_ids;
        if (activity_ids !== null) {
            if (activity_ids.constructor !== Array || typeof activity_ids == 'undefined') {
                activity_ids = null;
            }
        }

        // check classification ids
        var classification_ids = req.body.classification_ids;
        if (classification_ids !== null) {
            if (classification_ids.constructor !== Array || typeof classification_ids == 'undefined') {
                classification_ids = null;
            }
        }

        // check delete record boolean
        var delete_record = req.body.delete_record;
        if (typeof delete_record !== 'boolean') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a delete_record property in the JSON object of your HTTP POST." });
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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_edit_user_activity($1,$2,$3,$4,$5,$6)', [pmtInstance, request_user_id, target_user_id, activity_ids, classification_ids, delete_record], function (err, result) {
                done();
                if (err) {
                    console.log(err);
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                    return;
                }
                if (result.rows.length < 1) {
                    res.status(401).json({ errCode: 401, status: "ERROR", message: "Invalid request" });
                }
                // get the returned user information from the pmt_user funciton
                var userObj = result.rows[0].response;
                // fail if we don't get a good response.
                if (typeof userObj.id === 'undefined') {
                    res.status(401).json({ errCode: 401, status: "ERROR", message: "Invalid request" });
                }
                // completed update, proceed with success message
                else {
                    res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(JSON.stringify(userObj)) });
                    res.end(JSON.stringify(userObj));
                }
            });
        });
    }
    catch (ex) {
        console.log(ex);
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});

// validate username availablity
router.post('/pmt_validate_username', function (req, res) {
    try {
        // check username
        var username = req.body.username;
        if (typeof username !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a username as a string in the JSON object of your HTTP POST." });
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
        console.log(req.body);
        // create connection to database
        var conString = "postgres://" + config.pg[pmtId].user + ":" +
            config.pg[pmtId].password + "@" +
            config.pg[pmtId].host + "/" + config.pg[pmtId].database;
            console.log(conString);
        // call function
        pg.connect(conString, function (err, client, done) {
            if (err) {
                console.log(err);
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_validate_username($1)', [username.toString()], function (err, result) {
                done();
                console.log(result);
                if (err) {
                    console.log(err);
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                    return;
                }
                var anwser = result.rows[0].pmt_validate_username;

                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(anwser.toString()) });
                res.end(JSON.stringify(anwser));
            });
        });
    }
    catch (ex) {
        console.log(ex);
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});

// validate user authority availablity
router.post('/pmt_validate_user_authority', function (req, res) {
    try {

        // validate instance_id
        var instance_id = req.body.instance_id;
        if (typeof instance_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "You must specify a instance_id as an integer in the JSON of your HTTP POST." });
            return;
        }

        // validate user_id
        var user_id = req.body.user_id;
        if (typeof user_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a user_id as a number in the JSON object of your HTTP POST." });
            return;
        }

        // validate activity_id (optional paramater: required only for update & delete)
        var activity_id = req.body.activity_id;
        if (typeof activity_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a activity_id as a number in the JSON object of your HTTP POST." });
            return;
        }

        // validate data_group_id (optional paramater: required only for create)
        var data_group_id = req.body.data_group_id;
        if (typeof data_group_id !== 'number') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a data_group_id as a number in the JSON object of your HTTP POST." });
            return;
        }

        // validate auth type (pmt enum: create, update, delete, read)
        var auth_type = req.body.auth_type;
        if (typeof auth_type !== 'string') {
            res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide a auth_type as a string in the JSON object of your HTTP POST." });
            return;
        }
        else {
            if (auth_type !== 'create' && auth_type !== 'delete' && auth_type !== 'update' && auth_type !== 'read') {
                res.status(400).json({ errCode: 400, status: "ERROR", message: "Must provide auth_type as: create, delete, update, read, in the JSON object of your HTTP POST." });
                return;
            }
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
                res.status(500).json({ errCode: 500, status: "ERROR", message: "Unable to connect to database.", error: err });
                done();
                return;
            }
            client.query('SELECT * FROM pmt_validate_user_authority($1,$2,$3,$4,$5)', [instance_id, user_id, activity_id, data_group_id, auth_type], function (err, result) {
                done();
                if (err) {
                    console.log(err);
                    res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: err });
                    return;
                }
                var anwser = result.rows[0].pmt_validate_user_authority;
                res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(anwser) });
                res.end(JSON.stringify(anwser));
            });
        });
    }
    catch (ex) {
        console.log(ex);
        res.status(500).json({ errCode: 500, status: "ERROR", message: "There was an error in the execution of API request. Contact the administrator.", error: ex });
        return;
    }
});


function respondWithJWT(res, userObj) {

    var jwtObj = {
        pmtId: userObj.pmtId,
        permission: Util.permissionObjToBoolString(userObj.role_auth) // for some reason the role_auth is an array of objects?
    };

    var token = jwt.sign(jwtObj, config.auth.secret, {
        expiresIn: config.auth.expiresIn
    });

    jwtObj.token = token;
    jwtObj.user = userObj;

    res.set('Authorization', token)
        .set('Access-Control-Expose-Headers', 'Authorization')
        .json(jwtObj);

}

/**
 * Send an email from config specified server
 * @param opts mail server options
 * @param mail mail message options
 * @returns {*}
 */
function sendEmail(opts, mail) {

    var deferred = Q.defer();

    var transporter = nodemailer.createTransport(opts);

    // setup e-mail data with unicode symbols
    var mailOptions = {
        from: opts.auth.user, // Sender Address
        to: mail.email, // Recipient Address
        subject: mail.subject,  // Subject line
        text: mail.message // plain text body
    };

    // send mail with defined transport object
    transporter.sendMail(mailOptions, function (error, info) {
        if (error) {
            deferred.reject(error);
        } else {
            deferred.resolve(info.response);
        }
    });

    return deferred.promise;
}

module.exports = router;