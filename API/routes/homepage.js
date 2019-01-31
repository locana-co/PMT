var express = require('express');
var router = express.Router();

/* GET help page. */
router.get('/', function (req, res) {
    res.render('homepage', { title: 'PMT API - Help Pages' });
});

module.exports = router;
