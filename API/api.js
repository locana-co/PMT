//PMT API
var dotenv = require('dotenv');

// Declarations
var app; // application
var config; // application configuration information
// package variables
var express;
var path;
var favicon; // middleware for serving a favicon
var logger; // HTTP request logger
var cookieParser; // cookie parsing with signatures
var pg;  //postgresql connection
var bodyParser; // body parsing middleware
var requestIp; // get client ip addresses
var environment = 'production'; // default environment
// route variables
var agra;
var analysis;
var locations;
var contacts;
var details;
var activities;
var organizations;
var users;
var taxonomies;
var partnerlink;
var utility;

var debug = require('debug')('pmtapi');
var args = process.argv.slice(2);
console.log("Sent arguements: ",args);
console.log("Sent node env: ",process.env.NODE_ENV);
dotenv.load();

// load the application configuration file (config.js)
try {
    config = require('./config.js');
} catch (e) {
    console.log("No config.js file detected in root. This file is required.");
    process.exit(1);
}

// determine the target environment (first parameter passed to node)
if (args.length > 0) {
    switch (args[0]) {
        case 'stage':
            environment = 'stage';
            break;
        case 'demo':
            environment = 'demo';
            break;
        case 'local':
            environment = 'local';
            break;
        default:
            environment = 'local';
            break;
    }
}
// determine the target environment (parameter passed by pm2)
if (process.env.NODE_ENV) {
    switch (process.env.NODE_ENV) {
        case 'stage':
            environment = 'stage';
            break;
        case 'demo':
            environment = 'demo';
            break;
        case 'local':
            environment = 'local';
            break;
        default:
            environment = 'local';
            break;
    }
}
console.log('Environment set to: ' + environment);

// load the packages we need (package.json)
try {
    express = require("express");
    path = require('path');
    favicon = require('serve-favicon');
    logger = require('morgan');
    cookieParser = require('cookie-parser');
    pg = require('pg');
    bodyParser = require('body-parser');
    requestIp = require('request-ip');
    app = express();
    var expressJwt = require('express-jwt');
    var unless = require('express-unless');
} catch (e) {
    console.log("An error occurred during the loading of the packages. Please " +
        "check to ensure all the packages listed in the package.json file are installed (nvm).");
    process.exit(1);
}
// load the routes, each route has a file in the routes folder
try {
    agra = require('./routes/agra');
    homepage = require('./routes/homepage');
    analysis = require('./routes/analysis');
    contacts = require('./routes/contact');
    details = require('./routes/detail');
    locations = require('./routes/location');
    activities = require('./routes/activity');
    organizations = require('./routes/organization');
    users = require('./routes/user');
    taxonomies = require('./routes/taxonomy');
    partnerlink = require('./routes/partnerlink');
    utility = require('./routes/utility');

} catch (e) {
    console.log("An error occurred during the loading of the routes. Please " +
        "ensure all route files referenced are available in the ./routes folder. " +
        "Error message: " + e.message);
    process.exit(1);
}
// set the application settings
try {
    // title
    app.set('title', config.title);
    app.set('trust proxy', 'loopback');
    // view engine setup - using jade
    // https://www.npmjs.com/package/jade
    app.set('views', path.join(__dirname, 'views'));
    app.set('view engine', 'jade');

} catch (e) {
    console.log("An error occurred during the loading of the application settings." +
        "Error message: " + e.message);
    process.exit(1);
}
// connect the packages to the application (mount middleware)
try {
    app.use(favicon(__dirname + '/public/favicon.ico'));
    app.use(logger('dev'));
    app.use(bodyParser.json());
    app.use(bodyParser.urlencoded({ extended: true }));
    app.use(cookieParser());
    app.use(config.subDirectory[environment] + 'public', express.static(path.join(__dirname, '/public')));

    // Add headers
    app.use(function (req, res, next) {

        // Websites to provide access to the API
        res.setHeader('Access-Control-Allow-Origin', '*');
        //res.setHeader('Access-Control-Allow-Origin', 'http://v10.investmentmapping.org');

        // Request methods to allow
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');

        // Request headers to allow
        res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type,Authorization');

        // Set to true if you need the website to include cookies in the requests sent
        // to the API (e.g. in case you use sessions)
        res.setHeader('Access-Control-Allow-Credentials', true);

        // Pass to next layer of middleware
        next();
    });

    /**
     * Express JWT Middleware
     */
    expressJwt.unless = unless;
    app.use(expressJwt({
        secret: config.auth.secret,
        getToken: function fromHeaderOrQuerystring(req) {
            if (req.headers.authorization && req.headers.authorization.split(' ')[0] === 'Bearer') {
                return req.headers.authorization.split(' ')[1];
            } else if (req.query && req.query.token) {
                return req.query.token;
            }
            return null;
        }
    })
        // Paths that should not require auth
        .unless({
            path: [
                config.subDirectory[environment],  // help documentation is at the root
                config.subDirectory[environment] + 'pmt_user_auth' // user authentication route
            ]
        }));


    // Catch other errors like bogus JSON in a POST body
    // Also catch JWT Authorization failures.
    app.use(function (err, req, res, next) {
        if (err && err.name === 'UnauthorizedError') {
            err.authenticated = false;
            res.status(401).json(err);
        }
        else if (err) {
            res.status(err.status || 500).json({ status: 'ERROR', errCode: err.status || 500, error: err });
        }
    });

} catch (e) {
    console.log("An error occurred during the mounting of the application middleware." +
        "Error message: " + e.message);
    process.exit(1);
}

// set the routes
try {
    app.use(config.subDirectory[environment], homepage);
    app.use(config.subDirectory[environment], agra);
    app.use(config.subDirectory[environment], analysis);
    app.use(config.subDirectory[environment], contacts);
    app.use(config.subDirectory[environment], details);
    app.use(config.subDirectory[environment], locations);
    app.use(config.subDirectory[environment], activities);
    app.use(config.subDirectory[environment], organizations);
    app.use(config.subDirectory[environment], users);
    app.use(config.subDirectory[environment], taxonomies);
    app.use(config.subDirectory[environment], partnerlink);
    app.use(config.subDirectory[environment], utility);
} catch (e) {
    console.log("An error occurred while setting the routes." +
        "Error message: " + e.message);
    process.exit(1);
}

console.log('Magic happens on port ' + config.port[environment]);

app.listen(config.port[environment]);

